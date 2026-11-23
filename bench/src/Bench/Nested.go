package ffi

// The records that go through Yoga.Protobuf.Repeated, declared so that Iris hands them over as
// they are instead of as untyped values.

type Inner struct {
	A int32
	B string
}

type TagsEntry struct {
	Key   string
	Value int32
}
