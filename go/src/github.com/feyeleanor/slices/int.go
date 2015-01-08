package slices

import (
	"fmt"
	"strings"
)

type ISlice		[]int

func (s ISlice) Len() int							{ return len(s) }
func (s ISlice) Cap() int							{ return cap(s) }

func (s ISlice) At(i int) interface{}				{ return s[i] }
func (s ISlice) Set(i int, v interface{})			{ s[i] = v.(int) }
func (s ISlice) Clear(i int)						{ s[i] = 0 }
func (s ISlice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }

func (s ISlice) Negate(i int)						{ s[i] = -s[i] }
func (s ISlice) Increment(i int)					{ s[i]++ }
func (s ISlice) Decrement(i int)					{ s[i]-- }

func (s ISlice) Add(i, j int)						{ s[i] += s[j] }
func (s ISlice) Subtract(i, j int)					{ s[i] -= s[j] }
func (s ISlice) Multiply(i, j int)					{ s[i] *= s[j] }
func (s ISlice) Divide(i, j int)					{ s[i] /= s[j] }
func (s ISlice) Remainder(i, j int)					{ s[i] %= s[j] }

func (s ISlice) Sum() (r int) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s ISlice) Product() (r int) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s ISlice) And(i, j int)						{ s[i] &= s[j] }
func (s ISlice) Or(i, j int)						{ s[i] |= s[j] }
func (s ISlice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s ISlice) Invert(i int)						{ s[i] = ^s[i] }
func (s ISlice) ShiftLeft(i, j int)					{ s[i] <<= uint(s[j]) }
func (s ISlice) ShiftRight(i, j int)				{ s[i] >>= uint(s[j]) }

func (s ISlice) Less(i, j int) bool					{ return s[i] < s[j] }
func (s ISlice) AtLeast(i, j int) bool				{ return s[i] <= s[j] }
func (s ISlice) Same(i, j int) bool					{ return s[i] == s[j] }
func (s ISlice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s ISlice) More(i, j int) bool					{ return s[i] > s[j] }
func (s ISlice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s ISlice) ZeroAtLeast(i int) bool				{ return 0 <= s[i] }
func (s ISlice) ZeroSameAs(i int) bool				{ return 0 == s[i] }
func (s ISlice) ZeroAtMost(i int) bool				{ return 0 >= s[i] }
func (s ISlice) ZeroMoreThan(i int) bool			{ return 0 > s[i] }

func (s *ISlice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s ISlice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s ISlice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *ISlice) Cut(i, j int) {
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

func (s *ISlice) Trim(i, j int) {
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

func (s *ISlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *ISlice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(int) bool:			for i, v := range a {
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

func (s ISlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(int):							for _, v := range s { f(v) }
	case func(int, int):					for i, v := range s { f(i, v) }
	case func(interface{}, int):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s ISlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, int) bool:					for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, int) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ISlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, int) bool:					for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, int) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ISlice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s ISlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s ISlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(ISlice, count, count))
	}
}

func (s ISlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case ISlice:			copy(s[offset:], container)
	case []int:				copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *ISlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(ISlice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *ISlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *ISlice) Expand(i, n int) {
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
		x := make(ISlice, l, c)
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

func (s ISlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s ISlice) Depth() int {
	return 0
}

func (s *ISlice) Append(v interface{}) {
	switch v := v.(type) {
	case int:				*s = append(*s, v)
	case ISlice:			*s = append(*s, v...)
	case []int:				s.Append(ISlice(v))
	default:				panic(v)
	}
}

func (s *ISlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case int:				l := s.Len() + 1
							n := make(ISlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case ISlice:			l := s.Len() + len(v)
							n := make(ISlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []int:				s.Prepend(ISlice(v))
	default:				panic(v)
	}
}

func (s ISlice) Repeat(count int) ISlice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(ISlice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s ISlice) equal(o ISlice) (r bool) {
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

func (s ISlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case ISlice:			r = s.equal(o)
	case []int:				r = s.equal(o)
	}
	return
}

func (s ISlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s ISlice) Cdr() (t ISlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *ISlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = ISlice{v.(int)}
	case s.Len() == 0:		*s = append(*s, v.(int))
	default:				(*s)[0] = v.(int)
	}
}

func (s *ISlice) Rplacd(v interface{}) {
	if s == nil {
		*s = ISlice{v.(int)}
	} else {
		ReplaceSlice := func(v ISlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(ISlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case int:			(*s)[1] = v
							*s = (*s)[:2]
		case ISlice:		ReplaceSlice(v)
		case []int:			ReplaceSlice(ISlice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s ISlice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(int); ok {
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

func (s ISlice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(int); ok {
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

func (s *ISlice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case int:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(int) bool:			for i, v := range a {
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

func (s ISlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(int):							for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, int):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, int):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s ISlice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(int)
	switch f := f.(type) {
	case int:						for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(int) bool:			for i, v := range s {
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

func (s *ISlice) Replace(o interface{}) {
	switch o := o.(type) {
	case ISlice:			*s = o
	case []int:				*s = ISlice(o)
	default:				panic(o)
	}
}

func (s ISlice) Select(f interface{}) interface{} {
	r := make(ISlice, 0, len(s) / 4)
	switch f := f.(type) {
	case int:						for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(int) bool:			for _, v := range s {
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

func (s *ISlice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[int] bool)
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

func (s ISlice) Pick(n ...int) interface{} {
	r := make(ISlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *ISlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case int:				l := s.Len() + 1
							n := make(ISlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case ISlice:			l := s.Len() + len(v)
							n := make(ISlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []int:				s.Insert(i, ISlice(v))
	default:				panic(v)
	}
}

func (s *ISlice) Pop() (r int, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}