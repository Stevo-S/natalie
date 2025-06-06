#pragma once

#include <memory>
#include <setjmp.h>
#include <stdlib.h>
#include <string.h>
#include <vector>

#include "natalie/gc/heap_block.hpp"
#include "natalie/macros.hpp"
#include "tm/hashmap.hpp"

namespace Natalie {

using namespace TM;

class Allocator {
public:
    NAT_MAKE_NONCOPYABLE(Allocator);

    Allocator(size_t cell_size)
        : m_cell_size { cell_size } { }

    ~Allocator() {
        for (auto block : m_blocks) {
            block.first->~HeapBlock();
            free(block.first);
        }
    }

    size_t cell_size() const {
        return m_cell_size;
    }

    size_t cell_count_per_block() const {
        return (HEAP_BLOCK_SIZE - sizeof(HeapBlock)) / m_cell_size;
    }

    size_t total_cells() {
        return m_blocks.size() * cell_count_per_block();
    }

    size_t free_cells() const {
        return m_free_cells;
    }

    short int free_cells_percentage() {
        if (m_blocks.is_empty())
            return 0;
        return m_free_cells * 100 / total_cells();
    }

    void *allocate();

    void add_free_block(HeapBlock *block) {
        m_free_blocks.push_back(block);
        m_free_cells += block->free_count();
    }

    bool is_my_block(HeapBlock *candidate_block) {
        return m_blocks.get(candidate_block) != nullptr;
    }

    auto begin() {
        return m_blocks.begin();
    }

    auto end() {
        return m_blocks.end();
    }

    void unmark_all_cells_in_all_blocks() {
        for (auto block : *this) {
            block.first->unmark_all_cells();
        }
    }

    void add_multiple_blocks(int count) {
        for (int i = 0; i < count; ++i)
            add_heap_block();
    }

    void add_blocks_until_percent_free_reached(short int desired) {
        while (free_cells_percentage() < desired)
            add_heap_block();
    }

private:
    HeapBlock *add_heap_block();

    size_t m_cell_size;
    size_t m_free_cells { 0 };
    Hashmap<HeapBlock *> m_blocks {};
    std::vector<HeapBlock *> m_free_blocks {};
};

}
