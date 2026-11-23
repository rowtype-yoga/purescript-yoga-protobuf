// Writes the features samples as protoc-gen-go encodes them, to spec/fixtures/<name>.bin, for
// the specs that check the generated codecs against another implementation. The samples are the
// ones in spec/src/Test/Features/Samples.purs and spec/fixtures/js/fixtures.mjs.
//
//	go run . ..
package main

import (
	"os"
	"path/filepath"

	"google.golang.org/protobuf/proto"

	"yogapb/features/pb"
)

func main() {
	directory := os.Args[1]
	write(directory, "everything", everything())
	write(directory, "everything-without-oneofs", withoutOneofs(everything()))
	write(directory, "legacy", legacy())
}

// protoc-gen-go writes the fields of oneofs after all the others, where protobuf-es and this
// library write every field in the order of the numbers. Without oneofs, the bytes are the same.
func withoutOneofs(message *pb.Everything) *pb.Everything {
	message.Choice.Pick = nil
	message.Choice.Other = nil
	return message
}

func write(directory string, name string, message proto.Message) {
	data, err := proto.MarshalOptions{Deterministic: true}.Marshal(message)
	if err != nil {
		panic(err)
	}
	if err := os.WriteFile(filepath.Join(directory, name+".bin"), data, 0o644); err != nil {
		panic(err)
	}
}

func everything() *pb.Everything {
	return &pb.Everything{
		Scalars: &pb.Scalars{
			ADouble:    1.5,
			AFloat:     2.25,
			AnInt32:    -42,
			AnInt64:    -9000000000,
			AUint32:    4000000000,
			AUint64:    18000000000000000000,
			ASint32:    -7,
			ASint64:    -123456789012,
			AFixed32:   3000000000,
			AFixed64:   12345678901234,
			AnSfixed32: -5,
			AnSfixed64: -6000000000,
			ABool:      true,
			AString:    "héllo ☃",
			SomeBytes:  []byte{0, 1, 2, 255},
			AColour:    pb.Colour_COLOUR_BLUE,
			ALight:     pb.Light_LIGHT_AMBER,
			ADirection: pb.Direction_EAST_BY_NORTHEAST,
		},
		Optionals: &pb.Optionals{
			MaybeInt32:  proto.Int32(0),
			MaybeString: proto.String(""),
			MaybeColour: pb.Colour_COLOUR_RED.Enum(),
			MaybeUint64: proto.Uint64(7),
			MaybeBool:   proto.Bool(false),
		},
		Repeateds: &pb.Repeateds{
			Doubles:         []float64{1.5, -2.5},
			Floats:          []float32{0.5},
			Int32S:          []int32{1, -1, 300},
			Int64S:          []int64{-1, 5000000000},
			Uint32S:         []uint32{1, 4000000000},
			Uint64S:         []uint64{1},
			Sint32S:         []int32{-1, 1},
			Sint64S:         []int64{-2},
			Fixed32S:        []uint32{1, 2},
			Fixed64S:        []uint64{3},
			Sfixed32S:       []int32{-4},
			Sfixed64S:       []int64{-5},
			Bools:           []bool{true, false, true},
			Strings:         []string{"a", "", "ü"},
			ByteStrings:     [][]byte{{1}, {}},
			Colours:         []pb.Colour{pb.Colour_COLOUR_RED, pb.Colour_COLOUR_BLUE, 7},
			Messages:        []*pb.Scalars{{AnInt32: 1}, {}},
			UnpackedInt32S:  []int32{1, 2},
			UnpackedDoubles: []float64{0.25},
			UnpackedColours: []pb.Colour{pb.Colour_COLOUR_GREEN},
		},
		Maps: &pb.Maps{
			ByName:   map[string]int32{"one": 1, "two": 2, "zero": 0},
			Messages: map[int32]*pb.Scalars{1: {AString: "x"}, 3: {}},
			Colours:  map[uint32]pb.Colour{4000000000: pb.Colour_COLOUR_BLUE, 1: pb.Colour_COLOUR_RED},
			ByInt64:  map[int64]string{-5: "minus five", 5000000000: "big"},
			ByBool:   map[bool][]byte{false: {}, true: {9}},
			BySint32: map[int32]float64{-3: 0.5},
			Things:   map[uint64]*pb.Thing{2: {Name: "two", Mood: pb.Mood_MOOD_HAPPY}},
		},
		Choice: &pb.Choice{
			Pick:  &pb.Choice_Scalars{Scalars: &pb.Scalars{ABool: true}},
			After: "after",
			Other: &pb.Choice_Blob{Blob: []byte{7, 8}},
		},
		Tree: &pb.Tree{
			Label: "root",
			Left:  &pb.Tree{Label: "l"},
			Children: []*pb.Tree{
				{Label: "c1"},
				{Label: "c2", Left: &pb.Tree{Label: "c2l"}},
			},
			Named: map[string]*pb.Tree{"n": {Label: "named"}},
		},
		Outer: &pb.Outer{
			Inner:  &pb.Outer_Inner{Kind: pb.Outer_Inner_KIND_SMALL, Value: 5},
			Inners: []*pb.Outer_Inner{{Kind: pb.Outer_Inner_KIND_LARGE}, {}},
			Kind:   pb.Outer_Inner_KIND_LARGE,
		},
		Keywords: &pb.Keywords{Type: 1, Data: "d", Input: true, End: 4, Module: "m", Value: 6, Where: 7, Loop: 8, Position: 9},
		Uses: &pb.Uses{
			Thing:  &pb.Thing{Name: "thing", Mood: pb.Mood_MOOD_GRUMPY},
			Mood:   pb.Mood_MOOD_HAPPY,
			Things: []*pb.Thing{{Name: "a"}},
			Empty:  &pb.Empty{},
		},
		Wide: &pb.Wide{
			AnInt32:       1,
			AString:       "two",
			ADouble:       3.5,
			AnInt64:       4,
			ABool:         true,
			AUint32:       4000000000,
			ASint32:       -7,
			ASint64:       -8,
			AFixed32:      9,
			AFixed64:      10,
			AnSfixed32:    -11,
			AnSfixed64:    -12,
			AFloat:        13.5,
			SomeBytes:     []byte{14},
			AColour:       pb.Colour_COLOUR_GREEN,
			AUint64:       16,
			AnotherInt32:  17,
			AnotherString: "eighteen",
			AnotherDouble: 19.5,
			AnotherInt64:  20,
			AnotherBool:   true,
			LastString:    "thirty",
		},
		Empty: &pb.Empty{},
	}
}

func legacy() *pb.Legacy {
	return &pb.Legacy{
		Id:            proto.Int32(1),
		PackedNumbers: []int32{1, 2, 3},
		Numbers:       []int32{4, 5},
		Next: &pb.Legacy{
			Id:   proto.Int32(2),
			Name: proto.String("second"),
			Part: &pb.Legacy_Part{},
		},
		Part: &pb.Legacy_Part{On: proto.Bool(true)},
		Size: pb.Legacy_LARGE.Enum(),
	}
}
