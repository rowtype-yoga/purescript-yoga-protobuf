package ffi

import "bytes"

type Bytes = []byte

func EqImpl(left []byte, right []byte) bool { return bytes.Equal(left, right) }

func LengthImpl(data []byte) int32 { return int32(len(data)) }

func FromArrayImpl(numbers []int32) []byte {
	data := make([]byte, len(numbers))
	for index, number := range numbers {
		data[index] = byte(number)
	}
	return data
}

func ToArrayImpl(data []byte) []int32 {
	numbers := make([]int32, len(data))
	for index, value := range data {
		numbers[index] = int32(value)
	}
	return numbers
}

var EmptyImpl = []byte{}
