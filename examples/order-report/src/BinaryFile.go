package ffi

import (
	"bufio"
	"os"
)

func ReadBytesImpl(path string) []byte {
	data, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return data
}

func WriteChunksImpl(path string, chunks [][]byte) {
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	buffered := bufio.NewWriterSize(file, 1<<20)
	for _, chunk := range chunks {
		if _, err := buffered.Write(chunk); err != nil {
			panic(err)
		}
	}
	if err := buffered.Flush(); err != nil {
		panic(err)
	}
}
