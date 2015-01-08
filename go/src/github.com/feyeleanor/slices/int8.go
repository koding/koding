package slices

import (
	"fmt"
	"strings"
)

type I8Slice	[]int8

func (s I8Slice) Len() int							{ return len(s) }
func (s I8Slice) Cap() int							{ return cap(s) }

func (s I8Slice) At(i int) interface{}				{ return s[i] }
func (s I8Slice) Set(i int, v interface{})			{ s[i] = v.(int8) }
func (s I8Slice) Clear(i int)						{ s[i] = 0 }
func (s I8Slice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }

func (s I8Slice) Negate(i int)						{ s[i] = -s[i] }
func (s I8Slice) Increment(i int)					{ s[i]++ }
func (s I8Slice) Decrement(i int)					{ s[i]-- }

func (s I8Slice) Add(i, j int)						{ s[i] += s[j] }
func (s I8Slice) Subtract(i, j int)					{ s[i] -= s[j] }
func (s I8Slice) Multiply(i, j int)					{ s[i] *= s[j] }
func (s I8Slice) Divide(i, j int)					{ s[i] /= s[j] }
func (s I8Slice) Remainder(i, j int)				{ s[i] %= s[j] }

func (s I8Slice) Sum() (r int8) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s I8Slice) Product() (r int8) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s I8Slice) And(i, j int)						{ s[i] &= s[j] }
func (s I8Slice) Or(i, j int)						{ s[i] |= s[j] }
func (s I8Slice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s I8Slice) Invert(i int)						{ s[i] = ^s[i] }
func (s I8Slice) ShiftLeft(i, j int)				{ s[i] <<= uint(s[j]) }
func (s I8Slice) ShiftRight(i, j int)				{ s[i] >>= uint(s[j]) }

func (s I8Slice) Less(i, j int) bool				{ return s[i] < s[j] }
func (s I8Slice) AtLeast(i, j int) bool				{ return s[i] <= s[j] }
func (s I8Slice) Same(i, j int) bool				{ return s[i] == s[j] }
func (s I8Slice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s I8Slice) More(i, j int) bool				{ return s[i] > s[j] }
func (s I8Slice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s I8Slice) ZeroAtLeast(i int) bool			{ return 0 <= s[i] }
func (s I8Slice) ZeroSameAs(i int) bool				{ return 0 == s[i] }
func (s I8Slice) ZeroAtMost(i int) bool				{ return 0 >= s[i] }
func (s I8Slice) ZeroMoreThan(i int) bool			{ return 0 > s[i] }

func (s *I8Slice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s I8Slice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s I8Slice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *I8Slice) Cut(i, j int) {
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

func (s *I8Slice) Trim(i, j int) {
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

func (s *I8Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *I8Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int8:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(int8) bool:			for i, v := range a {
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

func (s I8Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(int8):						for _, v := range s { f(v) }
	case func(int, int8):					for i, v := range s { f(i, v) }
	case func(interface{}, int8):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s I8Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int8) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, int8) bool:					for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, int8) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s I8Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int8) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, int8) bool:					for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, int8) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s I8Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s I8Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s I8Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(I8Slice, count, count))
	}
}

func (s I8Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case I8Slice:			copy(s[offset:], container)
	case []int8:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *I8Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(I8Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *I8Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *I8Slice) Expand(i, n int) {
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
		x := make(I8Slice, l, c)
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

func (s I8Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s I8Slice) Depth() int {
	return 0
}

func (s *I8Slice) Append(v interface{}) {
	switch v := v.(type) {
	case int8:				*s = append(*s, v)
	case I8Slice:			*s = append(*s, v...)
	case []int8:			s.Append(I8Slice(v))
	default:				panic(v)
	}
}

func (s *I8Slice) Prepend(v interface{}) {
	switch v := v.(type) {
	case int8:				l := s.Len() + 1
							n := make(I8Slice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case I8Slice:			l := s.Len() + len(v)
							n := make(I8Slice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []int8:			s.Prepend(I8Slice(v))
	default:				panic(v)
	}
}

func (s I8Slice) Repeat(count int) I8Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(I8Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s I8Slice) equal(o I8Slice) (r bool) {
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

func (s I8Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case I8Slice:			r = s.equal(o)
	case []int8:			r = s.equal(o)
	}
	return
}

func (s I8Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s I8Slice) Cdr() (t I8Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *I8Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = I8Slice{v.(int8)}
	case s.Len() == 0:		*s = append(*s, v.(int8))
	default:				(*s)[0] = v.(int8)
	}
}

func (s *I8Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = I8Slice{v.(int8)}
	} else {
		ReplaceSlice := func(v I8Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(I8Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case int8:			(*s)[1] = v
							*s = (*s)[:2]
		case I8Slice:		ReplaceSlice(v)
		case []int8:		ReplaceSlice(I8Slice(v))
		case nil:			*s = (*s)[:1]
		default:			(*s)[1] = v.(int8)
							*s = (*s)[:2]
		}
	}
}

func (s I8Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(int8); ok {
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

func (s I8Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(int8); ok {
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

func (s *I8Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int8:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(int8) bool:			for i, v := range a {
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

func (s I8Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(int8):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, int8):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, int8):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s I8Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(int8)
	switch f := f.(type) {
	case int8:						for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(int8) bool:			for i, v := range s {
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

func (s *I8Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case int8:				*s = I8Slice{o}
	case I8Slice:			*s = o
	case []int8:			*s = I8Slice(o)
	default:				panic(o)
	}
}

func (s I8Slice) Select(f interface{}) interface{} {
	r := make(I8Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case int8:						for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(int8) bool:			for _, v := range s {
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

func (s *I8Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[int8] bool)
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

func (s I8Slice) Pick(n ...int) interface{} {
	r := make(I8Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *I8Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case int8:				l := s.Len() + 1
							n := make(I8Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case I8Slice:			l := s.Len() + len(v)
							n := make(I8Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []int8:			s.Insert(i, I8Slice(v))
	default:				panic(v)
	}
}

func (s *I8Slice) Pop() (r int8, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}