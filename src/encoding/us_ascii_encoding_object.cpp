#include "natalie/encoding/us_ascii_encoding_object.hpp"
#include "natalie.hpp"

namespace Natalie {

std::pair<bool, StringView> UsAsciiEncodingObject::prev_char(const String &string, size_t *index) const {
    if (*index == 0)
        return { true, StringView() };
    (*index)--;
    unsigned char c = string[*index];
    if ((int)c > 127)
        return { false, StringView(&string, *index, 1) };
    return { true, StringView(&string, *index, 1) };
}

std::pair<bool, StringView> UsAsciiEncodingObject::next_char(const String &string, size_t *index) const {
    if (*index >= string.size())
        return { true, StringView() };
    size_t i = *index;
    (*index)++;
    unsigned char c = string[i];
    if ((int)c > 127)
        return { false, StringView(&string, i, 1) };
    return { true, StringView(&string, i, 1) };
}

void UsAsciiEncodingObject::append_escaped_char(String &str, nat_int_t c) const {
    str.append_sprintf("\\x%02llX", c);
}

nat_int_t UsAsciiEncodingObject::to_unicode_codepoint(nat_int_t codepoint) const {
    return codepoint;
}

nat_int_t UsAsciiEncodingObject::from_unicode_codepoint(nat_int_t codepoint) const {
    if (codepoint >= 128)
        return -1;

    return codepoint;
}

String UsAsciiEncodingObject::encode_codepoint(nat_int_t codepoint) const {
    return String((char)codepoint);
}

nat_int_t UsAsciiEncodingObject::decode_codepoint(StringView &str) const {
    switch (str.size()) {
    case 1: {
        auto value = (unsigned char)str[0];
        if ((int)value > 127)
            return -1;
        return value;
    }
    default:
        return -1;
    }
}

bool UsAsciiEncodingObject::check_string_valid_in_encoding(const String &string) const {
    for (size_t i = 0; i < string.size(); i++) {
        unsigned char codepoint = string[i];
        if (!valid_codepoint(codepoint))
            return false;
    }
    return true;
}

}
