#pragma once

#include <assert.h>
#include <initializer_list>

#include "natalie/encoding/single_byte_encoding_object.hpp"
#include "natalie/string_object.hpp"

namespace Natalie {

using namespace TM;

class Windows1254EncodingObject : public SingleByteEncodingObject {
public:
    Windows1254EncodingObject();
};

}
