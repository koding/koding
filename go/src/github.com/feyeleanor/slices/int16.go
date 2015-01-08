package slices

import (
	"fmt"
	"strings"
)

type I16Slice	[]int16

func (s I16Slice) Len() int							{ return len(s) }
func (s I16Slice) Cap() int							{ return cap(s) }

func (s I16Slice) At(i int) interface{}				{ return s[i] }
func (s I16Slice) Set(i int, v interface{})			{ s[i] = v.(int16) }
func (s I16Slice) Clear(i int)						{ s[i] = 0 }
func (s I16Slice) Swap(i, j int)					{ s[i], s[j] = s[j], s[i] }

func (s I16Slice) Negate(i int)						{ s[i] = -s[i] }
func (s I16Slice) Increment(i int)					{ s[i]++ }
func (s I16Slice) Decrement(i int)					{ s[i]-- }

func (s I16Slice) Add(i, j int)						{ s[i] += s[j] }
func (s I16Slice) Subtract(i, j int)				{ s[i] -= s[j] }
func (s I16Slice) Multiply(i, j int)				{ s[i] *= s[j] }
func (s I16Slice) Divide(i, j int)					{ s[i] /= s[j] }
func (s I16Slice) Remainder(i, j int)				{ s[i] %= s[j] }

func (s I16Slice) Sum() (r int16) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s I16Slice) Product() (r int16) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s I16Slice) And(i, j int)						{ s[i] &= s[j] }
func (s I16Slice) Or(i, j int)						{ s[i] |= s[j] }
func (s I16Slice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s I16Slice) Invert(i int)						{ s[i] = ^s[i] }
func (s I16Slice) ShiftLeft(i, j int)				{ s[i] <<= uint(s[j]) }
func (s I16Slice) ShiftRight(i, j int)				{ s[i] >>= uint(s[j]) }

func (s I16Slice) Less(i, j int) bool				{ return s[i] < s[j] }
func (s I16Slice) AtLeast(i, j int) bool			{ return s[i] <= s[j] }
func (s I16Slice) Same(i, j int) bool				{ return s[i] == s[j] }
func (s I16Slice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s I16Slice) More(i, j int) bool				{ return s[i] > s[j] }
func (s I16Slice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s I16Slice) ZeroAtLeast(i int) bool			{ return 0 <= s[i] }
func (s I16Slice) ZeroSameAs(i int) bool			{ return 0 == s[i] }
func (s I16Slice) ZeroAtMost(i int) bool			{ return 0 >= s[i] }
func (s I16Slice) ZeroMoreThan(i int) bool			{ return 0 > s[i] }

func (s *I16Slice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s I16Slice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s I16Slice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *I16Slice) Cut(i, j int) {
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

func (s *I16Slice) Trim(i, j int) {
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

func (s *I16Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *I16Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int16:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(int16) bool:			for i, v := range a {
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

func (s I16Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(int16):						for _, v := range s { f(v) }
	case func(int, int16):					for i, v := range s { f(i, v) }
	case func(interface{}, int16):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s I16Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int16) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, int16) bool:					for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, int16) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s I16Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int16) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, int16) bool:					for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, int16) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s I16Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s I16Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s I16Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(I16Slice, count, count))
	}
}

func (s I16Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case I16Slice:			copy(s[offset:], container)
	case []int16:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *I16Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(I16Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *I16Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *I16Slice) Expand(i, n int) {
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
		x := make(I16Slice, l, c)
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

func (s I16Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s I16Slice) Depth() int {
	return 0
}

func (s *I16Slice) Append(v interface{}) {
	switch v := v.(type) {
	case int16:				*s = append(*s, v)
	case I16Slice:			*s = append(*s, v...)
	case []int16:			s.Append(I16Slice(v))
	default:				panic(v)
	}
}

func (s *I16Slice) Prepend(v interface{}) {
	switch v := v.(type) {
	case int16:				l := s.Len() + 1
							n := make(I16Slice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case I16Slice:			l := s.Len() + len(v)
							n := make(I16Slice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []int16:			s.Prepend(I16Slice(v))
	default:				panic(v)
	}
}

func (s I16Slice) Repeat(count int) I16Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(I16Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s I16Slice) equal(o I16Slice) (r bool) {
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

func (s I16Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case I16Slice:			r = s.equal(o)
	case []int16:			r = s.equal(o)
	}
	return
}

func (s I16Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s I16Slice) Cdr() (t I16Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *I16Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = I16Slice{v.(int16)}
	case s.Len() == 0:		*s = append(*s, v.(int16))
	default:				(*s)[0] = v.(int16)
	}
}

func (s *I16Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = I16Slice{v.(int16)}
	} else {
		ReplaceSlice := func(v I16Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(I16Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case int16:			(*s)[1] = v
							*s = (*s)[:2]
		case I16Slice:		ReplaceSlice(v)
		case []int16:		ReplaceSlice(I16Slice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s I16Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(int16); ok {
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

func (s I16Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(int16); ok {
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

func (s *I16Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int16:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(int16) bool:			for i, v := range a {
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

func (s I16Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(int16):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, int16):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, int16):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s I16Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(int16)
	switch f := f.(type) {
	case int16:						for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(int16) bool:			for i, v := range s {
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

func (s *I16Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case I16Slice:			*s = o
	case []int16:			*s = I16Slice(o)
	default:				panic(o)
	}
}

func (s I16Slice) Select(f interface{}) interface{} {
	r := make(I16Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case int16:						for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(int16) bool:			for _, v := range s {
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

func (s *I16Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[int16] bool)
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

func (s I16Slice) Pick(n ...int) interface{} {
	r := make(I16Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *I16Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case int16:				l := s.Len() + 1
							n := make(I16Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case I16Slice:			l := s.Len() + len(v)
							n := make(I16Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []int16:			s.Insert(i, I16Slice(v))
	default:				panic(v)
	}
}

func (s *I16Slice) Pop() (r int16, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}