package ffi

import (
	"encoding/binary"
	"math"
	"math/bits"
	"sync"
	"unicode/utf8"
)

// Buffer fills from the back: bytes[position:] is what has been written.
//
// The small writes make no room when they don't fit, which would take a call that keeps Go from
// inlining them. They note that the buffer overflowed and write over it from the end again, and
// Yoga.Protobuf.Writer.encodeWith encodes again with a buffer twice the size.
type Buffer struct {
	bytes      []byte
	position   int
	overflowed bool
}

type Writer = *Buffer

const initialCapacity = 1024

var writers = sync.Pool{New: func() any { return &Buffer{bytes: make([]byte, initialCapacity)} }}

func AcquireImpl(capacity int) *Buffer {
	writer := writers.Get().(*Buffer)
	if len(writer.bytes) < capacity {
		writer.bytes = make([]byte, capacity)
	}
	writer.position = len(writer.bytes)
	writer.overflowed = false
	return writer
}

func OverflowedImpl(writer *Buffer) bool { return writer.overflowed }

func CapacityImpl(writer *Buffer) int { return len(writer.bytes) }

func FinishImpl(writer *Buffer) []byte {
	result := make([]byte, len(writer.bytes)-writer.position)
	copy(result, writer.bytes[writer.position:])
	writers.Put(writer)
	return result
}

func WrittenImpl(writer *Buffer) int { return len(writer.bytes) - writer.position }

func (writer *Buffer) room(count int) {
	if writer.position < count {
		writer.position = len(writer.bytes)
		writer.overflowed = true
	}
}

func LengthSinceImpl(writer *Buffer, mark int) {
	writer.uvarint(uint64(len(writer.bytes) - writer.position - mark))
}

func (writer *Buffer) uvarint(value uint64) {
	writer.room(10)
	size := (bits.Len64(value|1) + 6) / 7
	writer.position -= size
	at := writer.position
	for value >= 0x80 {
		writer.bytes[at] = byte(value) | 0x80
		value >>= 7
		at++
	}
	writer.bytes[at] = byte(value)
}

func Uint32Impl(writer *Buffer, value int) { writer.uvarint(uint64(uint32(value))) }

func Int32Impl(writer *Buffer, value int) { writer.uvarint(uint64(int64(int32(value)))) }

func Int64Impl(writer *Buffer, low int, high int) {
	writer.uvarint(uint64(uint32(high))<<32 | uint64(uint32(low)))
}

func Fixed32Impl(writer *Buffer, value int) {
	writer.room(4)
	writer.position -= 4
	binary.LittleEndian.PutUint32(writer.bytes[writer.position:], uint32(value))
}

func Fixed64Impl(writer *Buffer, low int, high int) {
	writer.room(8)
	writer.position -= 8
	binary.LittleEndian.PutUint64(writer.bytes[writer.position:], uint64(uint32(high))<<32|uint64(uint32(low)))
}

func FloatImpl(writer *Buffer, value float64) {
	writer.room(4)
	writer.position -= 4
	binary.LittleEndian.PutUint32(writer.bytes[writer.position:], math.Float32bits(float32(value)))
}

func DoubleImpl(writer *Buffer, value float64) {
	writer.room(8)
	writer.position -= 8
	binary.LittleEndian.PutUint64(writer.bytes[writer.position:], math.Float64bits(value))
}

// StringImpl writes the text as UTF-8. Iris keeps strings as WTF-8, where a lone surrogate is
// ED A0-BF 80-BF; that becomes U+FFFD, as JavaScript's TextEncoder makes it.
func StringImpl(writer *Buffer, text string) {
	if !utf8.ValidString(text) {
		text = replaceSurrogates(text)
	}
	writer.reserve(len(text))
	writer.position -= len(text)
	copy(writer.bytes[writer.position:], text)
	writer.uvarint(uint64(len(text)))
}

func replaceSurrogates(text string) string {
	replaced := make([]byte, 0, len(text))
	for index := 0; index < len(text); {
		if index+2 < len(text) && text[index] == 0xED && text[index+1] >= 0xA0 {
			replaced = utf8.AppendRune(replaced, utf8.RuneError)
			index += 3
			continue
		}
		replaced = append(replaced, text[index])
		index++
	}
	return string(replaced)
}

func BytesImpl(writer *Buffer, value []byte) {
	writer.reserve(len(value))
	writer.position -= len(value)
	copy(writer.bytes[writer.position:], value)
	writer.uvarint(uint64(len(value)))
}

// reserve makes room right away for strings and bytes, whose writes aren't inlined anyway.
func (writer *Buffer) reserve(count int) {
	if writer.position >= count {
		return
	}
	used := len(writer.bytes) - writer.position
	capacity := max(2*len(writer.bytes), used+count+initialCapacity)
	grown := make([]byte, capacity)
	copy(grown[capacity-used:], writer.bytes[writer.position:])
	writer.bytes = grown
	writer.position = capacity - used
}
