#include "natalie.hpp"

using namespace Natalie;

#ifdef NAT_PRINT_OBJECTS
#define NAT_GC_DISABLE
#endif

/*NAT_DECLARATIONS*/

extern "C" Env *build_top_env() {
    auto env = Natalie::build_top_env();
    [[maybe_unused]] Value self = GlobalEnv::the()->main_obj();
    /*NAT_OBJ_INIT*/
    return env;
}

extern "C" Value *EVAL(Env *env, Value *result_memory) {
    /*NAT_EVAL_INIT*/

    [[maybe_unused]] Value self = GlobalEnv::the()->main_obj();
    volatile bool run_exit_handlers = true;

    // kinda hacky, but needed for top-level begin/rescue
    Args args;
    Block *block = nullptr;

    Value result = nullptr;
    try {
        // FIXME: top-level `return` in a Ruby script should probably be changed to `exit`.
        result = [&]() -> Value {
            /*NAT_EVAL_BODY*/
            return NilObject::the();
        }();
        run_exit_handlers = false;
        run_at_exit_handlers(env);
    } catch (ExceptionObject *exception) {
        handle_top_level_exception(env, exception, run_exit_handlers);
        result = nullptr;
    }
    memcpy(result_memory, &result, sizeof(Value));
    return result_memory;
}

int main(int argc, char *argv[]) {
#ifdef NAT_NATIVE_PROFILER
    NativeProfiler::enable();
#endif

    setvbuf(stdout, nullptr, _IOLBF, 1024);

    Env *env = ::build_top_env();
    ThreadObject::finish_main_thread_setup(env, __builtin_frame_address(0));

    trap_signal(SIGINT, sigint_handler);
    trap_signal(SIGPIPE, sigpipe_handler);
#if !defined(__APPLE__)
    trap_signal(SIGUSR1, gc_signal_handler);
    trap_signal(SIGUSR2, gc_signal_handler);
#endif

#ifndef NAT_GC_DISABLE
    Heap::the().gc_enable();
#endif
#ifdef NAT_GC_COLLECT_ALL_AT_EXIT
    Heap::the().set_collect_all_at_exit(true);
#endif

    if (argc > 0) {
        Value exe = new StringObject { argv[0] };
        env->global_set("$exe"_s, exe);
    }

    ArrayObject *ARGV = new ArrayObject { (size_t)argc };
    GlobalEnv::the()->Object()->const_set("ARGV"_s, ARGV);
    for (int i = 1; i < argc; i++) {
        ARGV->push(new StringObject { argv[i] });
    }

    Value result = nullptr;
    EVAL(env, &result);
    auto return_code = result ? 0 : 1;

#ifdef NAT_NATIVE_PROFILER
    NativeProfiler::the()->dump();
#endif
#ifdef NAT_PRINT_OBJECTS
    Heap::the().dump();
#endif
    clean_up_and_exit(return_code);
}
