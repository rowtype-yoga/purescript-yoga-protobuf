package ffi

import (
	"os"
	"runtime"
	"time"
)

var started = time.Now()

func Now() float64 { return float64(time.Since(started).Nanoseconds()) / 1e6 }

func Allocations() float64 {
	var statistics runtime.MemStats
	runtime.ReadMemStats(&statistics)
	return float64(statistics.Mallocs)
}

var Backend = "go"

func ReadFixture(name string) []byte {
	data, err := os.ReadFile("bench/fixtures/" + name + ".bin")
	if err != nil {
		panic(err)
	}
	return data
}

//go:noinline
func Opaque[A any](value A) A { return value }

var sunk int32

func Sink(value int32) { sunk += value }
