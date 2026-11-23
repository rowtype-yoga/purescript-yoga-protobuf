package ffi

import (
	"encoding/binary"
	"math"
	"unicode/utf8"
)

const (
	truncated       int32 = -1
	malformedVarint int32 = -2
	invalidWireType int32 = -3
	maxGroupDepth         = 100
)

func VarintEndImpl(input []byte, position int32, end int32) int32 {
	if position < end && input[position] < 0x80 {
		return position + 1
	}
	if position+1 < end && input[position+1] < 0x80 {
		return position + 2
	}
	return varintEndSlow(input, position, end)
}

func varintEndSlow(input []byte, position int32, end int32) int32 {
	limit := min(end, position+10)
	for index := position; index < limit; index++ {
		if input[index] < 0x80 {
			return index + 1
		}
	}
	if limit == end && end-position < 10 {
		return truncated
	}
	return malformedVarint
}

func DelimitedEndImpl(input []byte, position int32, start int32, end int32) int32 {
	if start < 0 {
		return start
	}
	if first := input[position]; first < 0x80 {
		if int32(first) <= end-start {
			return start + int32(first)
		}
		return truncated
	}
	length := lengthOf(input, position, start)
	if length < 0 || length > end-start {
		return truncated
	}
	return start + length
}

func lengthOf(input []byte, position int32, start int32) int32 {
	if start-position > 5 {
		return -1
	}
	var length uint64
	for index := start - 1; index >= position; index-- {
		length = length<<7 | uint64(input[index]&0x7f)
	}
	if length > math.MaxInt32 {
		return -1
	}
	return int32(length)
}

func SkipImpl(input []byte, tag int32, position int32, end int32) int32 {
	return skipField(input, tag, position, end, 0)
}

func skipField(input []byte, tag int32, position int32, end int32, depth int) int32 {
	if uint32(tag)>>3 == 0 {
		return invalidWireType
	}
	switch tag & 7 {
	case 0:
		return VarintEndImpl(input, position, end)
	case 1:
		if end-position < 8 {
			return truncated
		}
		return position + 8
	case 2:
		return DelimitedEndImpl(input, position, VarintEndImpl(input, position, end), end)
	case 3:
		return skipGroup(input, int32(uint32(tag)>>3), position, end, depth+1)
	case 5:
		if end-position < 4 {
			return truncated
		}
		return position + 4
	default:
		return invalidWireType
	}
}

func skipGroup(input []byte, fieldNumber int32, position int32, end int32, depth int) int32 {
	if depth > maxGroupDepth {
		return invalidWireType
	}
	at := position
	for {
		afterTag := VarintEndImpl(input, at, end)
		if afterTag < 0 {
			return afterTag
		}
		tag := Varint32Impl(input, at)
		if tag&7 == 4 {
			if int32(uint32(tag)>>3) == fieldNumber {
				return afterTag
			}
			return invalidWireType
		}
		at = skipField(input, tag, afterTag, end, depth)
		if at < 0 {
			return at
		}
	}
}

func Varint32Impl(input []byte, position int32) int32 {
	if uint(position) < uint(len(input)) && input[position] < 0x80 {
		return int32(input[position])
	}
	return int32(uint32(varintSlow(input, position)))
}

func varintSlow(input []byte, position int32) uint64 {
	var result uint64
	for shift := uint(0); shift < 64 && int(position) < len(input); shift += 7 {
		byte_ := input[position]
		position++
		result |= uint64(byte_&0x7f) << shift
		if byte_ < 0x80 {
			return result
		}
	}
	return result
}

func Varint64Impl(_ func(int32, int32) int64, input []byte, position int32) int64 {
	if uint(position) < uint(len(input)) && input[position] < 0x80 {
		return int64(input[position])
	}
	return int64(varintSlow(input, position))
}

func BoolImpl(input []byte, position int32) bool {
	if uint(position) < uint(len(input)) && input[position] < 0x80 {
		return input[position] != 0
	}
	return varintSlow(input, position) != 0
}

func Fixed32Impl(input []byte, position int32) int32 {
	return int32(binary.LittleEndian.Uint32(input[position:]))
}

func Fixed64Impl(_ func(int32, int32) int64, input []byte, position int32) int64 {
	return int64(binary.LittleEndian.Uint64(input[position:]))
}

func FloatImpl(input []byte, position int32) float64 {
	return float64(math.Float32frombits(binary.LittleEndian.Uint32(input[position:])))
}

func DoubleImpl(input []byte, position int32) float64 {
	return math.Float64frombits(binary.LittleEndian.Uint64(input[position:]))
}

// InvalidUtf8Impl is a lone surrogate in WTF-8, as Iris keeps strings. No UTF-8 decodes to it.
var InvalidUtf8Impl = "\xed\xa0\x80"

func StringImpl(input []byte, start int32, end int32) string {
	text := input[start:end]
	if utf8.Valid(text) {
		return string(text)
	}
	return InvalidUtf8Impl
}

func Utf8ValidImpl(input []byte, start int32, end int32) bool {
	return utf8.Valid(input[start:end])
}

func BytesImpl(input []byte, start int32, end int32) []byte {
	return append([]byte(nil), input[start:end]...)
}

func PackedVarintsValidImpl(input []byte, start int32, end int32) bool {
	run := 0
	for _, byte_ := range input[start:end] {
		if byte_ < 0x80 {
			run = 0
		} else if run++; run >= 10 {
			return false
		}
	}
	return run == 0
}
