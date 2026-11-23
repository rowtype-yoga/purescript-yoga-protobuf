package ffi

type Fields = []int32

func NewImpl(_ []byte, count int32) []int32 {
	fields := make([]int32, count)
	for number := range fields {
		fields[number] = -1
	}
	return fields
}

func NoteImpl(fields []int32, wireTypes []int32, tag int32, position int32) []int32 {
	number := uint32(tag) >> 3
	if number < uint32(len(wireTypes)) && number < uint32(len(fields)) && wireTypes[number] == tag&7 {
		fields[number] = position
	}
	return fields
}

func AtImpl(fields []int32, number int32) int32 { return fields[number] }
