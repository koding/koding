package slices

import (
	"fmt"
	"strings"
)

type U32Slice	[]uint32

func (s U32Slice) Len() int							{ return len(s) }
func (s U32Slice) Cap() int							{ return cap(s) }

func (s U32Slice) At(i int) interface{}				{ return s[i] }
func (s U32Slice) Set(i int, v interface{})			{ s[i] = v.(uint32) }
func (s U32Slice) Clear(i int)						{ s[i] = 0 }
func (s U32Slice) Swap(i, j int)					{ s[i], s[j] = s[j], s[i] }

func (s U32Slice) Negate(i int)						{ s[i] = -s[i] }
func (s U32Slice) Increment(i int)					{ s[i]++ }
func (s U32Slice) Decrement(i int)					{ s[i]++ }

func (s U32Slice) Add(i, j int)						{ s[i] += s[j] }
func (s U32Slice) Subtract(i, j int)				{ s[i] -= s[j] }
func (s U32Slice) Multiply(i, j int)				{ s[i] *= s[j] }
func (s U32Slice) Divide(i, j int)					{ s[i] /= s[j] }
func (s U32Slice) Remainder(i, j int)				{ s[i] %= s[j] }

func (s U32Slice) Sum() (r uint32) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s U32Slice) Product() (r uint32) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s U32Slice) And(i, j int)						{ s[i] &= s[j] }
func (s U32Slice) Or(i, j int)						{ s[i] |= s[j] }
func (s U32Slice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s U32Slice) Invert(i int)						{ s[i] = ^s[i] }
func (s U32Slice) ShiftLeft(i, j int)				{ s[i] <<= s[j] }
func (s U32Slice) ShiftRight(i, j int)				{ s[i] >>= s[j] }

func (s U32Slice) Less(i, j int) bool				{ return s[i] < s[j] }
func (s U32Slice) AtLeast(i, j int) bool			{ return s[i] <= s[j] }
func (s U32Slice) Same(i, j int) bool				{ return s[i] == s[j] }
func (s U32Slice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s U32Slice) More(i, j int) bool				{ return s[i] > s[j] }
func (s U32Slice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s U32Slice) ZeroAtLeast(i int) bool			{ return true }
func (s U32Slice) ZeroSameAs(i int) bool			{ return 0 == s[i] }
func (s U32Slice) ZeroAtMost(i int) bool			{ return 0 == s[i] }
func (s U32Slice) ZeroMoreThan(i int) bool			{ return false }

func (s *U32Slice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s U32Slice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s U32Slice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *U32Slice) Cut(i, j int) {
	a := *s
	l := len(a)
	if i < 0 {
		i = 0
	}
	if j > l {
		j = l
	}
	if j > i {
		l -= j - i
		copy(a[i:], a[j:])
		*s = a[:l]
	}
}

func (s *U32Slice) Trim(i, j int) {
	a := *s
	n := len(a)
	if i < 0 {
		i = 0
	}
	if j > n {
		j = n
	}
	if j > i {
		copy(a, a[i:j])
		*s = a[:j - i]
	}
}

func (s *U32Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *U32Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uint32:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(uint32) bool:			for i, v := range a {
										if i != p {
											a[p] = v
										}
										if !f(v) {
											p++
										}
									}

	case func(interface{}) bool:	for i, v := range a {
										if i != p {
											a[p] = v
										}
										if !f(v) {
											p++
										}
									}

	default:						panic(f)
	}
	*s = a[:p]
}

func (s U32Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint32):						for _, v := range s { f(v) }
	case func(int, uint32):					for i, v := range s { f(i, v) }
	case func(interface{}, uint32):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s U32Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(uint32) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, uint32) bool:				for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, uint32) bool:		for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s U32Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(uint32) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, uint32) bool:				for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, uint32) bool:		for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s U32Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s U32Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s U32Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(U32Slice, count, count))
	}
}

func (s U32Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case U32Slice:			copy(s[offset:], container)
	case []uint32:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *U32Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(U32Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *U32Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *U32Slice) Expand(i, n int) {
	if i < 0 {
		i = 0
	}

	l := s.Len()
	if l < i {
		i = l
	}

	l += n
	c := s.Cap()
	if c < l {
		c = l
	}

	if c != s.Cap() {
		x := make(U32Slice, l, c)
		copy(x, (*s)[:i])
		copy(x[i + n:], (*s)[i:])
		*s = x
	} else {
		a := (*s)[:l]
		for j := l - 1; j >= i; j-- {
			a[j] = a[j - n]
		}
		*s = a
	}
}

func (s U32Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s U32Slice) Depth() int {
	return 0
}

func (s *U32Slice) Append(v interface{}) {
	switch v := v.(type) {
	case uint32:			*s = append(*s, v)
	case U32Slice:			*s = append(*s, v...)
	case []uint32:			s.Append(U32Slice(v))
	default:				panic(v)
	}
}

func (s *U32Slice) Prepend(v interface{}) {
	switch v := v.(type) {
	case uint32:			l := s.Len() + 1
							n := make(U32Slice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case U32Slice:			l := s.Len() + len(v)
							n := make(U32Slice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []uint32:			s.Prepend(U32Slice(v))
	default:				panic(v)
	}
}

func (s U32Slice) Repeat(count int) U32Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(U32Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s U32Slice) equal(o U32Slice) (r bool) {
	if len(s) == len(o) {
		r = true
		for i, v := range s {
			if r = v == o[i]; !r {
				return
			}
		}
	}
	return
}

func (s U32Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case U32Slice:			r = s.equal(o)
	case []uint32:			r = s.equal(o)
	}
	return
}

func (s U32Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s U32Slice) Cdr() (t U32Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *U32Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = U32Slice{v.(uint32)}
	case s.Len() == 0:		*s = append(*s, v.(uint32))
	default:				(*s)[0] = v.(uint32)
	}
}

func (s *U32Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = U32Slice{v.(uint32)}
	} else {
		ReplaceSlice := func(v U32Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(U32Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case uint32:		(*s)[1] = v
							*s = (*s)[:2]
		case U32Slice:		ReplaceSlice(v)
		case []uint32:		ReplaceSlice(U32Slice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s U32Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(uint32); ok {
		for j, x := range s {
			if x == v {
				i = j
				found = true
				break
			}
		}
	}
	return
}

func (s U32Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(uint32); ok {
		i = make(ISlice, 0, 0)
		for j, x := range s {
			if x == v {
				i = append(i, j)
				if len(i) == n {
					break
				}
			}
		}
	}
	return
}

func (s *U32Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uint32:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(uint32) bool:		for i, v := range a {
										if i != p {
											a[p] = v
										}
										if f(v) {
											p++
										}
									}

	case func(interface{}) bool:	for i, v := range a {
										if i != p {
											a[p] = v
										}
										if f(v) {
											p++
										}
									}

	default:						panic(f)
	}
	*s = a[:p]
}

func (s U32Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(uint32):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, uint32):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, uint32):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s U32Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(uint32)
	switch f := f.(type) {
	case uint32:					for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(uint32) bool:			for i, v := range s {
										if f(v) {
											s[i] = replacement
										}
									}

	case func(interface{}) bool:	for i, v := range s {
										if f(v) {
											s[i] = replacement
										}
									}

	default:						panic(f)
	}
}

func (s *U32Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case uint32:			*s = U32Slice{o}
	case U32Slice:			*s = o
	case []uint32:			*s = U32Slice(o)
	default:				panic(o)
	}
}

func (s U32Slice) Select(f interface{}) interface{} {
	r := make(U32Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case uint32:					for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(uint32) bool:		for _, v := range s {
										if f(v) {
											r = append(r, v)
										}
									}

	case func(interface{}) bool:	for _, v := range s {
										if f(v) {
											r = append(r, v)
										}
									}

	default:						panic(f)
	}
	return r
}

func (s *U32Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[uint32] bool)
		for _, v := range a {
			if ok := m[v]; !ok {
				m[v] = true
				a[p] = v
				p++
			}
		}
		*s = a[:p]
	}
}

func (s U32Slice) Pick(n ...int) interface{} {
	r := make(U32Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *U32Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case uint32:			l := s.Len() + 1
							n := make(U32Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case U32Slice:			l := s.Len() + len(v)
							n := make(U32Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []uint32:			s.Insert(i, U32Slice(v))
	default:				panic(v)
	}
}

func (s *U32Slice) Pop() (r uint32, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}