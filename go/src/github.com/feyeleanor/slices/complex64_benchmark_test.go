package slices

import "testing"

func BenchmarkC64SliceString(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.String()
	}
}

func BenchmarkC64Slice_len(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = len(sC64)
	}
}

func BenchmarkC64SliceLen(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Len()
	}
}

func BenchmarkC64Slice_cap(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = cap(sC64)
	}
}

func BenchmarkC64SliceCap(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Cap()
	}
}

func BenchmarkC64Slice_at(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = sC64[0]
	}
}

func BenchmarkC64SliceAt(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.At(0)
	}
}

func BenchmarkC64Slice_set(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] = 0
	}
}

func BenchmarkC64SliceSet(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Set(0, complex64(0))
	}
}

func BenchmarkC64Slice_clear(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] = 0
	}
}

func BenchmarkC64SliceClear(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Clear(0)
	}
}

func BenchmarkC64Slice_swap(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0], sC64[1] = sC64[1], sC64[0]
	}
}

func BenchmarkC64SliceSwap(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Swap(0, 1)
	}
}

func BenchmarkC64Slice_negate(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] = -sC64[0]
	}
}

func BenchmarkC64SliceNegate(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Negate(0)
	}
}

func BenchmarkC64Slice_increment(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0]++
	}
}

func BenchmarkC64SliceIncrement(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Increment(0)
	}
}

func BenchmarkC64Slice_decrement(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0]--
	}
}

func BenchmarkC64SliceDecrement(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Decrement(0)
	}
}

func BenchmarkC64Slice_add(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] += sC64[1]
	}
}

func BenchmarkC64SliceAdd(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Add(0, 1)
	}
}

func BenchmarkC64Slice_subtract(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] -= sC64[1]
	}
}

func BenchmarkC64SliceSubtract(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Subtract(0, 1)
	}
}

func BenchmarkC64Slice_multiply(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] *= sC64[1]
	}
}

func BenchmarkC64SliceMultiply(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Multiply(0, 1)
	}
}

func BenchmarkC64Slice_divide(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64[0] /= sC64[1]
	}
}

func BenchmarkC64SliceDivide(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Divide(0, 1)
	}
}

func BenchmarkC64Slice_sum(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		var x complex64
		for _, v := range sC64 {
			x += v
		}
	}
}

func BenchmarkC64SliceSum(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Sum()
	}
}

func BenchmarkC64Slice_product(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		x := complex64(1)
		for _, v := range sC64 {
			x *= v
		}
	}
}

func BenchmarkC64SliceProduct(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Product()
	}
}

func BenchmarkC64Slice_less(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = real(sC64[0]) < real(sC64[1])
	}
}

func BenchmarkC64SliceLess(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Less(0, 1)
	}
}

func BenchmarkC64Slice_at_least(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = real(sC64[0]) <= real(sC64[1])
	}
}

func BenchmarkC64SliceAtLeast(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.AtLeast(0, 1)
	}
}

func BenchmarkC64Slice_same(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = real(sC64[0]) == real(sC64[1])
	}
}

func BenchmarkC64SliceSame(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Same(0, 1)
	}
}

func BenchmarkC64Slice_at_most(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = real(sC64[0]) >= real(sC64[1])
	}
}

func BenchmarkC64SliceAtMost(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.AtMost(0, 1)
	}
}

func BenchmarkC64Slice_more(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = real(sC64[0]) > real(sC64[1])
	}
}

func BenchmarkC64SliceMore(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.More(0, 1)
	}
}

func BenchmarkC64Slice_zero_less_than(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = 0 < real(sC64[0])
	}
}

func BenchmarkC64SliceZeroLessThan(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroLessThan(0)
	}
}

func BenchmarkC64Slice_zero_at_least(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = 0 <= real(sC64[0])
	}
}

func BenchmarkC64SliceZeroAtLeast(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroAtLeast(0)
	}
}

func BenchmarkC64Slice_zero_same_as(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = 0 == real(sC64[0])
	}
}

func BenchmarkC64SliceZeroSameAs(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroSameAs(0)
	}
}

func BenchmarkC64Slice_zero_at_most(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = 0 >= real(sC64[0])
	}
}

func BenchmarkC64SliceZeroAtMost(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroAtMost(0)
	}
}

func BenchmarkC64Slice_zero_more_than(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = 0 > real(sC64[0])
	}
}

func BenchmarkC64SliceZeroMoreThan(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroMoreThan(0)
	}
}

func BenchmarkC64Slice_restrict_to(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_= sC64[0:10]
	}
}

func BenchmarkC64SliceRestrictTo(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.RestrictTo(0, 10)
	}
}

func BenchmarkC64SliceCompare1(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Compare(0, 1)
	}
}

func BenchmarkC64SliceCompare2(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Compare(1, 0)
	}
}

func BenchmarkC64SliceCompare3(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.Compare(0, 0)
	}
}

func BenchmarkC64SliceZeroCompare1(b *testing.B) {
	sC64 := C64Slice{-1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroCompare(0)
	}
}

func BenchmarkC64SliceZeroCompare2(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroCompare(0)
	}
}

func BenchmarkC64SliceZeroCompare3(b *testing.B) {
	sC64 := C64Slice{0, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		sC64.ZeroCompare(0)
	}
}

func BenchmarkC64Slice_cut_1(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = sC64[1:]
	}
}

func BenchmarkC64SliceCut1(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(0, 1)
	}
}

func BenchmarkC64Slice_cut_2(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = sC64[9:]
	}
}

func BenchmarkC64SliceCut2(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(9, 1)
	}
}

func BenchmarkC64Slice_cut_3(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = append(sC64[0:4], sC64[5:]...)
	}
}

func BenchmarkC64SliceCut3(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(4, 1)
	}
}

func BenchmarkC64Slice_cut_1a(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = sC64[1:]
	}
}

func BenchmarkC64SliceCut1a(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(0, 1)
	}
}

func BenchmarkC64Slice_cut_2a(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = sC64[19:]
	}
}

func BenchmarkC64SliceCut2a(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(19, 1)
	}
}

func BenchmarkC64Slice_cut_3a(b *testing.B) {
	sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i := 0; i < b.N; i++ {
		_ = append(sC64[0:9], sC64[10:]...)
	}
}

func BenchmarkC64SliceCut3a(b *testing.B) {
    for i := 0; i < b.N; i++ {
		sC64 := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		sC64.Cut(9, 1)
	}
}






func BenchmarkC64SliceExpand10(b *testing.B) {
    for i := 0; i < b.N; i++ {
		s := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		s.Expand(5, 10)
	}
}

func BenchmarkC64SliceExpand100(b *testing.B) {
    for i := 0; i < b.N; i++ {
		s := C64Slice{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		s.Expand(5, 100)
	}
}