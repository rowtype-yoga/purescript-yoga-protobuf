package ffi

import "slices"

type Repeated[A any] = []A

func EmptyImpl[A any]() []A { return nil }

func SnocImpl[A any](values []A, value A) []A { return append(values, value) }

func ReserveImpl[A any](values []A, count int32) []A { return slices.Grow(values, int(count)) }

// FreezeImpl drops the spare capacity, so that appending to the array later copies it.
func FreezeImpl[A any](values []A) []A { return slices.Clip(values) }
