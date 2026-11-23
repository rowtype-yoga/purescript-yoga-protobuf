package ffi

import "slices"

type Repeated[A any] = []A

func EmptyImpl[A any]() []A { return nil }

func SnocImpl[A any](values []A, value A) []A { return append(values, value) }

// FreezeImpl drops the spare capacity, so that appending to the array later copies it.
func FreezeImpl[A any](values []A) []A { return slices.Clip(values) }
