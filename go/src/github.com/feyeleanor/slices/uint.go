package slices

import (
	"fmt"
	"strings"
)

type USlice		[]uint

func (s USlice) Len() int							{ return len(s) }
func (s USlice) Cap() int							{ return cap(s) }

func (s USlice) At(i int) interface{}				{ return s[i] }
func (s USlice) Set(i int, v interface{})			{ s[i] = v.(uint) }
func (s USlice) Clear(i int)						{ s[i] = 0 }
func (s USlice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }

func (s USlice) Negate(i int)						{ s[i] = -s[i] }
func (s USlice) Increment(i int)					{ s[i]++ }
func (s USlice) Decrement(i int)					{ s[i]-- }

func (s USlice) Add(i, j int)						{ s[i] += s[j] }
func (s USlice) Subtract(i, j int)					{ s[i] -= s[j] }
func (s USlice) Multiply(i, j int)					{ s[i] *= s[j] }
func (s USlice) Divide(i, j int)					{ s[i] /= s[j] }
func (s USlice) Remainder(i, j int)					{ s[i] %= s[j] }

func (s USlice) Sum() (r uint) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s USlice) Product() (r uint) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s USlice) And(i, j int)						{ s[i] &= s[j] }
func (s USlice) Or(i, j int)						{ s[i] |= s[j] }
func (s USlice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s USlice) Invert(i int)						{ s[i] = ^s[i] }
func (s USlice) ShiftLeft(i, j int)					{ s[i] <<= s[j] }
func (s USlice) ShiftRight(i, j int)				{ s[i] >>= s[j] }

func (s USlice) Less(i, j int) bool					{ return s[i] < s[j] }
func (s USlice) AtLeast(i, j int) bool				{ return s[i] <= s[j] }
func (s USlice) Same(i, j int) bool					{ return s[i] == s[j] }
func (s USlice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s USlice) More(i, j int) bool					{ return s[i] > s[j] }
func (s USlice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s USlice) ZeroAtLeast(i int) bool				{ return true }
func (s USlice) ZeroSameAs(i int) bool				{ return 0 == s[i] }
func (s USlice) ZeroAtMost(i int) bool				{ return 0 == s[i] }
func (s USlice) ZeroMoreThan(i int) bool			{ return false }

func (s *USlice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s USlice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s USlice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *USlice) Cut(i, j int) {
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

func (s *USlice) Trim(i, j int) {
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

func (s *USlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *USlice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uint:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(uint) bool:			for i, v := range a {
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

func (s USlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint):						for _, v := range s { f(v) }
	case func(int, uint):					for i, v := range s { f(i, v) }
	case func(interface{}, uint):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s USlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(uint) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, uint) bool:					for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, uint) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s USlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(uint) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, uint) bool:					for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, uint) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s USlice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s USlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s USlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(USlice, count, count))
	}
}

func (s USlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case USlice:			copy(s[offset:], container)
	case []uint:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *USlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(USlice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *USlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *USlice) Expand(i, n int) {
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
		x := make(USlice, l, c)
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

func (s USlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s USlice) Depth() int {
	return 0
}

func (s *USlice) Append(v interface{}) {
	switch v := v.(type) {
	case uint:				*s = append(*s, v)
	case USlice:			*s = append(*s, v...)
	case []uint:			s.Append(USlice(v))
	default:				panic(v)
	}
}

func (s *USlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case uint:				l := s.Len() + 1
							n := make(USlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case USlice:			l := s.Len() + len(v)
							n := make(USlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []uint:			s.Prepend(USlice(v))
	default:				panic(v)
	}
}

func (s USlice) Repeat(count int) USlice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(USlice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s USlice) equal(o USlice) (r bool) {
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

func (s USlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case USlice:			r = s.equal(o)
	case []uint:			r = s.equal(o)
	}
	return
}

func (s USlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s USlice) Cdr() (t USlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *USlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = USlice{v.(uint)}
	case s.Len() == 0:		*s = append(*s, v.(uint))
	default:				(*s)[0] = v.(uint)
	}
}

func (s *USlice) Rplacd(v interface{}) {
	if s == nil {
		*s = USlice{v.(uint)}
	} else {
		ReplaceSlice := func(v USlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(USlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case uint:			(*s)[1] = v
							*s = (*s)[:2]
		case USlice:		ReplaceSlice(v)
		case []uint:		ReplaceSlice(USlice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s USlice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(uint); ok {
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

func (s USlice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(uint); ok {
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

func (s *USlice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uint:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(uint) bool:			for i, v := range a {
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

func (s USlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(uint):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, uint):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, uint):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s USlice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(uint)
	switch f := f.(type) {
	case uint:						for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(uint) bool:			for i, v := range s {
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

func (s *USlice) Replace(o interface{}) {
	switch o := o.(type) {
	case uint:				*s = USlice{o}
	case USlice:			*s = o
	case []uint:			*s = USlice(o)
	default:				panic(o)
	}
}

func (s USlice) Select(f interface{}) interface{} {
	r := make(USlice, 0, len(s) / 4)
	switch f := f.(type) {
	case uint:						for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(uint) bool:			for _, v := range s {
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

func (s *USlice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[uint] bool)
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

func (s USlice) Pick(n ...int) interface{} {
	r := make(USlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *USlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case uint:				l := s.Len() + 1
							n := make(USlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case USlice:			l := s.Len() + len(v)
							n := make(USlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []uint:			s.Insert(i, USlice(v))
	default:				panic(v)
	}
}

func (s *USlice) Pop() (r uint, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}