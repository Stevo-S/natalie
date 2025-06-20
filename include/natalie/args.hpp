#pragma once

#include "tm/optional.hpp"
#include "tm/string.hpp"
#include "tm/vector.hpp"
#include <initializer_list>
#include <stddef.h>
#include <stdio.h>

namespace Natalie {

using namespace TM;

class ArrayObject;
class Env;
class HashObject;
class SymbolObject;
class Value;

extern thread_local Vector<Value> *tl_current_arg_stack;

class Args {
public:
    Args() { }
    Args(size_t size, const Value *data, bool has_keyword_hash = false);
    Args(const TM::Vector<Value> &vec, bool has_keyword_hash = false);
    Args(ArrayObject *array, bool has_keyword_hash = false);
    Args(std::initializer_list<Value> args, bool has_keyword_hash = false);
    Args(Args &other);

    Args(Args &&other)
        : m_args_start_index { other.m_args_start_index }
        , m_args_original_start_index { other.m_args_original_start_index }
        , m_args_size { other.m_args_size }
        , m_args_original_size { other.m_args_original_size }
        , m_keyword_hash_index { other.m_keyword_hash_index } {
        other.m_moved_out = true;
        other.m_keyword_hash_index = -1;
    }

    ~Args() {
        if (!m_moved_out)
            tl_current_arg_stack->set_size(m_args_original_start_index);
    }

    Args &operator=(const Args &other) = delete;

    Value shift(Env *env, bool include_keyword_hash = true);
    Value pop(Env *env, bool include_keyword_hash = true);

    Value first() const;
    Value last() const;

    Value operator[](size_t index) const;

    Value at(size_t index) const;
    Value at(size_t index, Value default_value) const;
    Optional<Value> maybe_at(size_t index) const;

    ArrayObject *to_array(bool include_keyword_hash = true) const;
    ArrayObject *to_array_for_block(Env *env, ssize_t min_count, ssize_t max_count, bool autosplat, bool include_keyword_hash = true) const;

    Args copy() const {
        return Args(size(), data(), has_keyword_hash());
    }

    void ensure_argc_is(Env *env, size_t expected, bool has_keywords = false, std::initializer_list<const String> keywords = {}) const;
    void ensure_argc_between(Env *env, size_t expected_low, size_t expected_high, bool has_keywords = false, std::initializer_list<const String> keywords = {}) const;
    void ensure_argc_at_least(Env *env, size_t expected, bool has_keywords = false, std::initializer_list<const String> keywords = {}) const;

    enum class KeywordRestType {
        None,
        Present, // **kwargs
        Forbidden // **nil
    };
    void check_keyword_args(Env *env, std::initializer_list<SymbolObject *> required_keywords, std::initializer_list<SymbolObject *> optional_keywords, KeywordRestType keyword_rest_type) const;

    size_t start_index() const { return m_args_start_index; }
    size_t original_start_index() const { return m_args_original_start_index; }

    size_t size(bool include_keywords = true) const {
        if (has_keyword_hash())
            return include_keywords ? m_args_size : m_args_size - 1;
        return m_args_size;
    }

    size_t original_size(bool include_keywords = true) const {
        if (has_keyword_hash())
            return include_keywords ? m_args_original_size : m_args_original_size - 1;
        return m_args_original_size;
    }

    Value *data() const;

    bool has_keyword_hash() const { return m_keyword_hash_index != -1; }
    HashObject *keyword_hash() const;
    HashObject *pop_keyword_hash();
    void pop_empty_keyword_hash();
    Value keyword_arg(Env *, SymbolObject *) const;
    bool keyword_arg_present(Env *, SymbolObject *) const;
    HashObject *keyword_arg_rest(Env *, std::initializer_list<SymbolObject *>) const;

private:
    // Args cannot be heap-allocated, because the GC is not aware of it.
    void *operator new(size_t size) = delete;

    String argc_error_suffix(std::initializer_list<const String> keywords) const;

    size_t m_args_start_index { tl_current_arg_stack->size() };
    size_t m_args_original_start_index { tl_current_arg_stack->size() };
    size_t m_args_size { 0 };
    size_t m_args_original_size { m_args_size };
    ssize_t m_keyword_hash_index { -1 };
    bool m_moved_out { false };
};
};
