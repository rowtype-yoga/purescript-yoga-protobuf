package ffi

import "bytes"

type Bytes = []byte

func EqImpl(left []byte, right []byte) bool { return bytes.Equal(left, right) }

func LengthImpl(data []byte) int { return len(data) }

func FromArrayImpl(numbers []int) []byte {
	data := make([]byte, len(numbers))
	for index, number := range numbers {
		data[index] = byte(number)
	}
	return data
}

func ToArrayImpl(data []byte) []int {
	numbers := make([]int, len(data))
	for index, value := range data {
		numbers[index] = int(value)
	}
	return numbers
}

var EmptyImpl = []byte{}
