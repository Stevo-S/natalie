#include "natalie.hpp"

namespace Natalie {

Value Method::call(Env *env, Value self, Args &&args, Block *block) const {
    assert(m_fn);

    Env *closure_env = nullptr;
    if (has_env())
        closure_env = m_env;
    Env e { closure_env };
    e.set_caller(env);
    e.set_method(this);
    e.set_file(env->file());
    e.set_line(env->line());
    e.set_block(block);

    if (m_self) {
        self = m_self;
    }

    auto call_fn = [&](Args &&args) {
        if (block && !block->calling_env()) {
            Defer clear_calling_env([&]() {
                block->clear_calling_env();
            });
            block->set_calling_env(env);
            return m_fn(&e, self, std::move(args), block);
        } else {
            return m_fn(&e, self, std::move(args), block);
        }
    };

    // This code handles the "fast" integer/float optimization, where certain
    // IntegerObject and FloatObject methods do not allow their `this` or their
    // arguments to escape outside their call stack, i.e. they only live for a
    // short period. Thus the objects can be stack-allocated for speed, and the
    // GC need not allocate or collect them.
    if (m_optimized) {
        if (args.size() == 1 && args[0].is_fast_integer()) {
            auto synthesized_arg = IntegerObject { args[0].get_fast_integer() };
            synthesized_arg.add_synthesized_flag();
            return call_fn({ &synthesized_arg });
        } else if (args.size() == 1 && args[0].holds_raw_double()) {
            auto synthesized_arg = FloatObject { args[0].as_double() };
            synthesized_arg.add_synthesized_flag();
            return call_fn({ &synthesized_arg });
        }
    } else if (!self.is_fast_integer() && self->is_synthesized()) {
        // Turn this object into a heap-allocated one.
        self = self->duplicate(env);
    }

    return call_fn(std::move(args));
}
}
