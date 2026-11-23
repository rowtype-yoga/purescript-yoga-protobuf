package ffi

type Repeated[A any] []A

func Empty[A any]() Repeated[A] { return nil }

// SnocImpl starts with room for four values rather than one: repeated fields mostly have a
// few, and growing a slice from one to two to four is two allocations more.
func SnocImpl[A any](values Repeated[A], value A) Repeated[A] {
	if cap(values) == 0 {
		values = make(Repeated[A], 0, 4)
	}
	return append(values, value)
}

func Freeze[A any](values Repeated[A]) []A { return values }

func Thaw[A any](values []A) Repeated[A] { return values }
