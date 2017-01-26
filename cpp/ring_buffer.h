//
//  ring_buffer.h
//  2Term
//
//  Created by Kelvin Sherlock on 1/25/2017.
//
//

#ifndef ring_buffer_h
#define ring_buffer_h

#include <stdint.h>
#include <assert.h>


template<size_t Size>
class ring_buffer {
    
    static_assert((Size & ~(Size - 1)) == Size, "Size must be power of 2");
    
public:
    
    
    void write(uint8_t x) {
        _buffer[_ptr] = x;
        _ptr = (_ptr + 1) & ~(Size-1);
        if (_capacity) --_capacity;
    }
    
    void write(const uint8_t *data, size_t dsize) {
        if (!dsize) return;
        
        // simple replace.
        if (dsize >= Size) {
            _ptr = _capacity = 0;
            memcpy(_buffer, data + dsize - Size, Size);

            assert(_redzone == 0);
            return;
        }
        
        // simple append.
        if (_capacity >= dsize) {
            memcpy(_buffer + _ptr, data, _capacity);
            _ptr += dsize;
            _capacity -= dsize;

            assert(_redzone == 0);
            
            return;
        }
        // no capacity left.. overwrite.
        // dsize < Size.
        
        _capacity = 0;
        int amt = Size - _ptr;

        if (amt > dsize) {
            memcpy(_buffer + _ptr, data, dsize);
            _ptr += dsize;

            assert(_redzone == 0);
            return;
        }
        
        //amt = dsize;
        memcpy(_buffer + _ptr, data, amt);
        data += amt;
        dsize -= amt;
        memcpy(_buffer, data, dsize);
        _ptr = dsize;
        _capacity = 0;
        
        assert(_redzone == 0);
    }
    
    
    std::vector<uint8_t> read() const {
        std::vector<uint8_t> rv;
        if (_capacity) {
            rv.assign(_buffer, _buffer + _ptr);
            return rv;
        }
        // _ptr ... end, 0 .. _ptr
        rv.assign(_buffer + _ptr, _buffer + Size);
        if (_ptr) rv.insert(rv.end(), _buffer, _buffer + _ptr);
        return rv;
    }
    
    size_t size() const {
        return Size - _capacity;
    }

    bool empty() const {
        return _capacity == Size;
    }
    
    void clear() {
        _ptr = 0;
        _capacity = Size;
    }
    
    
private:
    size_t _capacity = Size;
    size_t _ptr = 0;
    uint8_t _buffer[Size];
    uint64_t _redzone = 0;
};






#endif /* ring_buffer_h */
