package grime

import "core:mem"

RingBuffer :: struct($T: typeid) {
    data:   []T,
    head:   int,
    tail:   int,
    len:    int,
    is_full: bool,
}

init :: proc(rb: ^RingBuffer($T), capacity: int, allocator := context.allocator) -> mem.Allocator_Error {
    data, err := make([]T, capacity, allocator)
    if err != nil {
        return err
    }
    rb.data = data
    rb.head = 0
    rb.tail = 0
    rb.len = 0
    rb.is_full = false
    return nil
}

destroy :: proc(rb: ^RingBuffer($T)) {
    delete(rb.data)
    rb^ = {}
}

len :: proc(rb: RingBuffer($T)) -> int {
    return rb.len
}

cap :: proc(rb: RingBuffer($T)) -> int {
    return len(rb.data)
}

is_empty :: proc(rb: RingBuffer($T)) -> bool {
    return rb.len == 0
}

is_full :: proc(rb: RingBuffer($T)) -> bool {
    return rb.is_full
}

push_back :: proc(rb: ^RingBuffer($T), value: T) {
    if rb.is_full {
        rb.data[rb.head] = value
        rb.head = (rb.head + 1) % len(rb.data)
        rb.tail = rb.head
    } else {
        rb.data[rb.tail] = value
        rb.tail = (rb.tail + 1) % len(rb.data)
        rb.len += 1
        rb.is_full = rb.len == len(rb.data)
    }
}

pop_front :: proc(rb: ^RingBuffer($T)) -> (T, bool) {
    if rb.len == 0 {
        return T{}, false
    }
    
    value := rb.data[rb.head]
    rb.head = (rb.head + 1) % len(rb.data)
    rb.len -= 1
    rb.is_full = false
    return value, true
}

get :: proc(rb: RingBuffer($T), index: int) -> (T, bool) {
    if index < 0 || index >= rb.len {
        return T{}, false
    }
    actual_index := (rb.head + index) % len(rb.data)
    return rb.data[actual_index], true
}

RingBufferIterator :: struct($T: typeid) {
    rb: ^RingBuffer(T),
    current: int,
}

iterator :: proc(rb: ^RingBuffer($T)) -> RingBufferIterator(T) {
    return RingBufferIterator(T){rb = rb, current = 0}
}

next :: proc(it: ^RingBufferIterator($T)) -> (T, bool) {
    if it.current >= it.rb.len {
        return T{}, false
    }
    value, _ := get(it.rb^, it.current)
    it.current += 1
    return value, true
}
