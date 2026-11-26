package ffi

type Fields = []int

func NewImpl(_ []byte, count int) []int {
	fields := make([]int, count)
	for number := range fields {
		fields[number] = -1
	}
	return fields
}

func NoteImpl(fields []int, wireTypes []int, tag int, position int) []int {
	number := uint32(tag) >> 3
	if number < uint32(len(wireTypes)) && number < uint32(len(fields)) && wireTypes[number] == tag&7 {
		fields[number] = position
	}
	return fields
}

func AtImpl(fields []int, number int) int { return fields[number] }
