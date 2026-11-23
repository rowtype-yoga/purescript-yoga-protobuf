package ffi

type Repeated[A any] []A

func Empty[A any]() Repeated[A] { return nil }

func SnocImpl[A any](values Repeated[A], value A) Repeated[A] { return append(values, value) }

func Freeze[A any](values Repeated[A]) []A { return values }

func Thaw[A any](values []A) Repeated[A] { return values }
