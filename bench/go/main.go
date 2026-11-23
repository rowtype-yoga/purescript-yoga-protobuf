// The Go comparators: protoc-gen-go, vtprotobuf and hyperpb, on the same samples as the
// PureScript benchmark, measured the same way. Prints
// `RESULT <implementation> <message> <encode|decode> <ns/op> <allocs/op>`.
//
//	go run . -fixtures ../fixtures   writes the samples' bytes for the PureScript checks
//	go run .                         measures
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"buf.build/go/hyperpb"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"

	"yogapb/bench/pb"
)

func main() {
	fixtures := flag.String("fixtures", "", "directory to write the samples' encodings to, instead of measuring")
	flag.Parse()
	samples := map[string]proto.Message{
		"nested":          nestedSample(),
		"repeated-nested": repeatedNestedSample(),
		"wide":            wideSample(),
	}
	if *fixtures != "" {
		writeFixtures(*fixtures, samples)
		return
	}
	measureProtocGenGo(samples)
	measureVtprotobuf(samples)
	measureHyperpb(samples, false)
	measureHyperpb(samples, true)
}

func nestedSample() *pb.Msg {
	tags := map[string]int32{}
	for index := 1; index <= 5; index++ {
		tags[fmt.Sprintf("key%d", index)] = int32(index * 100)
	}
	nums := make([]int32, 20)
	for index := range nums {
		nums[index] = int32(index + 1)
	}
	return &pb.Msg{
		Id: 12345, Big: 1234567890123, Name: "hello world, this is a name", Nums: nums,
		Inner: &pb.Inner{A: 7, B: "inner string"}, Tags: tags, Score: 3.14159, Ok: true,
		Labels: []string{"alpha", "beta", "gamma"},
	}
}

func repeatedNestedSample() *pb.RepeatedNested {
	items := make([]*pb.Inner, 1000)
	for index := range items {
		items[index] = &pb.Inner{A: int32(index), B: fmt.Sprintf("item %d", index)}
	}
	return &pb.RepeatedNested{Items: items}
}

// wideSample sets field n by its kind: int32 n*1000+7, string "field n", double n.25,
// int64 n*10^10, bool true, the same as Bench.Wide.sample.
func wideSample() *pb.Wide {
	wide := &pb.Wide{}
	message := wide.ProtoReflect()
	fields := message.Descriptor().Fields()
	for index := range fields.Len() {
		field := fields.Get(index)
		number := int64(field.Number())
		switch field.Kind() {
		case protoreflect.Int32Kind:
			message.Set(field, protoreflect.ValueOfInt32(int32(number*1000+7)))
		case protoreflect.StringKind:
			message.Set(field, protoreflect.ValueOfString(fmt.Sprintf("field %d", number)))
		case protoreflect.DoubleKind:
			message.Set(field, protoreflect.ValueOfFloat64(float64(number)+0.25))
		case protoreflect.Int64Kind:
			message.Set(field, protoreflect.ValueOfInt64(number*10_000_000_000))
		case protoreflect.BoolKind:
			message.Set(field, protoreflect.ValueOfBool(true))
		}
	}
	return wide
}

func writeFixtures(directory string, samples map[string]proto.Message) {
	for name, sample := range samples {
		data, err := proto.MarshalOptions{Deterministic: true}.Marshal(sample)
		if err != nil {
			panic(err)
		}
		if err := os.WriteFile(filepath.Join(directory, name+".bin"), data, 0o644); err != nil {
			panic(err)
		}
	}
}

var iterations = map[string]int{"nested": 200_000, "repeated-nested": 2_000, "wide": 200_000}

var sunk int

func measure(implementation string, name string, operation string, run func()) {
	count := iterations[name]
	for range count / 10 {
		run()
	}
	var before, after runtime.MemStats
	started := time.Now()
	runtime.ReadMemStats(&before)
	for range count {
		run()
	}
	runtime.ReadMemStats(&after)
	elapsed := time.Since(started)
	fmt.Printf("RESULT %s %s %s %f %f\n", implementation, name, operation,
		float64(elapsed.Nanoseconds())/float64(count), float64(after.Mallocs-before.Mallocs)/float64(count))
}

func measureProtocGenGo(samples map[string]proto.Message) {
	for _, name := range []string{"nested", "repeated-nested", "wide"} {
		sample := samples[name]
		data, _ := proto.Marshal(sample)
		measure("protoc-gen-go", name, "encode", func() {
			encoded, _ := proto.Marshal(sample)
			sunk += len(encoded)
		})
		measure("protoc-gen-go", name, "decode", func() {
			decoded := sample.ProtoReflect().New().Interface()
			if err := proto.Unmarshal(data, decoded); err != nil {
				panic(err)
			}
			sunk += readGeneratedFields(decoded)
		})
	}
}

type vtMessage interface {
	proto.Message
	MarshalVT() ([]byte, error)
	UnmarshalVT([]byte) error
}

func measureVtprotobuf(samples map[string]proto.Message) {
	for _, name := range []string{"nested", "repeated-nested", "wide"} {
		sample := samples[name].(vtMessage)
		data, _ := sample.MarshalVT()
		measure("vtprotobuf", name, "encode", func() {
			encoded, _ := sample.MarshalVT()
			sunk += len(encoded)
		})
		measure("vtprotobuf", name, "decode", func() {
			decoded := sample.ProtoReflect().New().Interface().(vtMessage)
			if err := decoded.UnmarshalVT(data); err != nil {
				panic(err)
			}
			sunk += readGeneratedFields(decoded)
		})
	}
}

// measureHyperpb decodes into an arena that each decode frees again, as hyperpb suggests for
// throughput. hyperpb only decodes. With `guided`, the parser is recompiled from a profile of
// decoding the sample, hyperpb's profile-guided optimization.
func measureHyperpb(samples map[string]proto.Message, guided bool) {
	implementation := "hyperpb"
	if guided {
		implementation = "hyperpb-pgo"
	}
	for _, name := range []string{"nested", "repeated-nested", "wide"} {
		sample := samples[name]
		data, _ := proto.Marshal(sample)
		messageType := hyperpb.CompileMessageDescriptor(sample.ProtoReflect().Descriptor())
		if guided {
			profile := messageType.NewProfile()
			for range 1000 {
				message := hyperpb.NewMessage(messageType)
				if err := message.Unmarshal(data, hyperpb.WithRecordProfile(profile, 1)); err != nil {
					panic(err)
				}
			}
			messageType = messageType.Recompile(profile)
		}
		shared := new(hyperpb.Shared)
		measure(implementation, name, "decode", func() {
			message := shared.NewMessage(messageType)
			if err := message.Unmarshal(data); err != nil {
				panic(err)
			}
			sunk += readFields(message)
			shared.Free()
		})
	}
}

// readGeneratedFields reads what the PureScript benchmark reads of each message: a field or three.
func readGeneratedFields(message proto.Message) int {
	switch decoded := message.(type) {
	case *pb.Msg:
		return int(decoded.Id)
	case *pb.RepeatedNested:
		return len(decoded.Items)
	case *pb.Wide:
		return len(decoded.F2) + int(decoded.F23) + int(int32(decoded.F49))
	}
	panic("unknown message")
}

// readFields reads the same through reflection, which is how hyperpb's messages are read.
func readFields(message protoreflect.Message) int {
	fields := message.Descriptor().Fields()
	switch message.Descriptor().Name() {
	case "Msg":
		return int(message.Get(fields.ByNumber(1)).Int())
	case "RepeatedNested":
		return message.Get(fields.ByNumber(1)).List().Len()
	default:
		return len(message.Get(fields.ByNumber(2)).String()) +
			int(message.Get(fields.ByNumber(23)).Float()) +
			int(int32(message.Get(fields.ByNumber(49)).Int()))
	}
}
