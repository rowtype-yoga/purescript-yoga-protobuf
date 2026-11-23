package ffi

import (
	"encoding/binary"
	"math"
	"math/bits"
	"sync"
	"unicode/utf8"
)

// Buffer fills from the back: bytes[position:] is what has been written.
type Buffer struct {
	bytes    []byte
	position int
}

type Writer = *Buffer

const initialCapacity = 1024

// Writers are pooled, so encoding a message allocates only its result.
var writers = sync.Pool{New: func() any { return &Buffer{bytes: make([]byte, initialCapacity)} }}

func AcquireImpl() *Buffer {
	writer := writers.Get().(*Buffer)
	writer.position = len(writer.bytes)
	return writer
}

func FinishImpl(writer *Buffer) []byte {
	result := make([]byte, len(writer.bytes)-writer.position)
	copy(result, writer.bytes[writer.position:])
	writers.Put(writer)
	return result
}

func WrittenImpl(writer *Buffer) int32 { return int32(len(writer.bytes) - writer.position) }

func (writer *Buffer) reserve(count int) {
	if writer.position >= count {
		return
	}
	used := len(writer.bytes) - writer.position
	capacity := max(2*len(writer.bytes), used+count)
	grown := make([]byte, capacity)
	copy(grown[capacity-used:], writer.bytes[writer.position:])
	writer.bytes = grown
	writer.position = capacity - used
}

func LengthSinceImpl(writer *Buffer, mark int32) {
	writer.uvarint(uint64(len(writer.bytes) - writer.position - int(mark)))
}

func (writer *Buffer) uvarint(value uint64) {
	if value < 0x80 && writer.position > 0 {
		writer.position--
		writer.bytes[writer.position] = byte(value)
		return
	}
	writer.uvarintSlow(value)
}

func (writer *Buffer) uvarintSlow(value uint64) {
	size := (bits.Len64(value|1) + 6) / 7
	writer.reserve(size)
	writer.position -= size
	at := writer.position
	for value >= 0x80 {
		writer.bytes[at] = byte(value) | 0x80
		value >>= 7
		at++
	}
	writer.bytes[at] = byte(value)
}

func Uint32Impl(writer *Buffer, value int32) { writer.uvarint(uint64(uint32(value))) }

func Int32Impl(writer *Buffer, value int32) { writer.uvarint(uint64(int64(value))) }

func Int64Impl(writer *Buffer, low int32, high int32) {
	writer.uvarint(uint64(uint32(high))<<32 | uint64(uint32(low)))
}

func Fixed32Impl(writer *Buffer, value int32) {
	writer.reserve(4)
	writer.position -= 4
	binary.LittleEndian.PutUint32(writer.bytes[writer.position:], uint32(value))
}

func Fixed64Impl(writer *Buffer, low int32, high int32) {
	writer.reserve(8)
	writer.position -= 8
	binary.LittleEndian.PutUint64(writer.bytes[writer.position:], uint64(uint32(high))<<32|uint64(uint32(low)))
}

func FloatImpl(writer *Buffer, value float64) {
	writer.reserve(4)
	writer.position -= 4
	binary.LittleEndian.PutUint32(writer.bytes[writer.position:], math.Float32bits(float32(value)))
}

func DoubleImpl(writer *Buffer, value float64) {
	writer.reserve(8)
	writer.position -= 8
	binary.LittleEndian.PutUint64(writer.bytes[writer.position:], math.Float64bits(value))
}

// StringImpl writes the text as UTF-8. Iris keeps strings as WTF-8, where a lone surrogate is
// ED A0-BF 80-BF; that becomes U+FFFD, as JavaScript's TextEncoder makes it.
func StringImpl(writer *Buffer, text string) {
	if !utf8.ValidString(text) {
		text = replaceSurrogates(text)
	}
	writer.reserve(len(text) + 5)
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
	writer.reserve(len(value) + 5)
	writer.position -= len(value)
	copy(writer.bytes[writer.position:], value)
	writer.uvarint(uint64(len(value)))
}
