package slices

import (
	"fmt"
	"strings"
)

type C128Slice	[]complex128

func (s C128Slice) Len() int						{ return len(s) }
func (s C128Slice) Cap() int						{ return cap(s) }

func (s C128Slice) At(i int) interface{}			{ return s[i] }
func (s C128Slice) Set(i int, v interface{})		{ s[i] = v.(complex128) }
func (s C128Slice) Clear(i int)						{ s[i] = 0 }
func (s C128Slice) Swap(i, j int)					{ s[i], s[j] = s[j], s[i] }

func (s C128Slice) Negate(i int)					{ s[i] = -s[i] }
func (s C128Slice) Increment(i int)					{ s[i]++ }
func (s C128Slice) Decrement(i int)					{ s[i]-- }

func (s C128Slice) Add(i, j int)					{ s[i] += s[j] }
func (s C128Slice) Subtract(i, j int)				{ s[i] -= s[j] }
func (s C128Slice) Multiply(i, j int)				{ s[i] *= s[j] }
func (s C128Slice) Divide(i, j int)					{ s[i] /= s[j] }

func (s C128Slice) Sum() (r complex128) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s C128Slice) Product() (r complex128) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s C128Slice) Less(i, j int) bool				{ return real(s[i]) < real(s[j]) }
func (s C128Slice) AtLeast(i, j int) bool			{ return real(s[i]) <= real(s[j]) }
func (s C128Slice) Same(i, j int) bool				{ return real(s[i]) == real(s[j]) }
func (s C128Slice) AtMost(i, j int) bool			{ return real(s[i]) >= real(s[j]) }
func (s C128Slice) More(i, j int) bool				{ return real(s[i]) > real(s[j]) }

func (s C128Slice) ZeroLessThan(i int) bool			{ return 0 < real(s[i]) }
func (s C128Slice) ZeroAtLeast(i int) bool			{ return 0 <= real(s[i]) }
func (s C128Slice) ZeroSameAs(i int) bool			{ return 0 == real(s[i]) }
func (s C128Slice) ZeroAtMost(i int) bool			{ return 0 >= real(s[i]) }
func (s C128Slice) ZeroMoreThan(i int) bool			{ return 0 > real(s[i]) }

func (s *C128Slice) RestrictTo(i, j int)			{ *s = (*s)[i:j] }

func (s C128Slice) Compare(i, j int) (r int) {
	switch x, y := real(s[i]), real(s[j]); {
	case x < y:			r = IS_LESS_THAN
	case x > y:			r = IS_GREATER_THAN
	default:			r = IS_SAME_AS
	}
	return
}

func (s C128Slice) ZeroCompare(i int) (r int) {
	switch x := real(s[i]); {
	case 0 < x:			r = IS_LESS_THAN
	case 0 > x:			r = IS_GREATER_THAN
	default:			r = IS_SAME_AS
	}
	return
}

func (s *C128Slice) Cut(i, j int) {
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

func (s *C128Slice) Trim(i, j int) {
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

func (s *C128Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *C128Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case complex128:				for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(complex128) bool:		for i, v := range a {
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

func (s C128Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(complex128):					for _, v := range s { f(v) }
	case func(int, complex128):				for i, v := range s { f(i, v) }
	case func(interface{}, complex128):		for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s C128Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(complex128) bool:					for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, complex128) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, complex128) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s C128Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(complex128) bool:					for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, complex128) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, complex128) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s C128Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s C128Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s C128Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(C128Slice, count, count))
	}
}

func (s C128Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case C128Slice:				copy(s[offset:], container)
	case []complex128:			copy(s[offset:], container)
	default:					panic(container)
	}
}

func (s *C128Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(C128Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *C128Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *C128Slice) Expand(i, n int) {
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
		x := make(C128Slice, l, c)
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

func (s C128Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s C128Slice) Depth() int {
	return 1
}

func (s C128Slice) Repeat(count int) C128Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(C128Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s C128Slice) equal(o C128Slice) (r bool) {
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

func (s C128Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case C128Slice:				r = s.equal(o)
	case []complex128:			r = s.equal(o)
	}
	return
}

func (s C128Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s C128Slice) Cdr() (t C128Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *C128Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = C128Slice{v.(complex128)}
	case s.Len() == 0:		*s = append(*s, v.(complex128))
	default:				(*s)[0] = v.(complex128)
	}
}

func (s *C128Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = C128Slice{v.(complex128)}
	} else {
		ReplaceSlice := func(v C128Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(C128Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case complex128:		(*s)[1] = v
								*s = (*s)[:2]
		case C128Slice:			ReplaceSlice(v)
		case []complex128:		ReplaceSlice(C128Slice(v))
		case nil:				*s = (*s)[:1]
		default:				panic(v)
		}
	}
}

func (s C128Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(complex128); ok {
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

func (s C128Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(complex128); ok {
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

func (s *C128Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case complex128:				for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(complex128) bool:		for i, v := range a {
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

func (s C128Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(complex128):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, complex128):				for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, complex128):		for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s C128Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(complex128)
	switch f := f.(type) {
	case complex128:				for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(complex128) bool:		for i, v := range s {
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

func (s *C128Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case complex128:		*s = C128Slice{o}
	case C128Slice:			*s = o
	case []complex128:		*s = C128Slice(o)
	default:				panic(o)
	}
}

func (s C128Slice) Select(f interface{}) interface{} {
	r := make(C128Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case complex128:				for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(complex128) bool:		for _, v := range s {
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

func (s *C128Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[complex128] bool)
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

func (s C128Slice) Pick(n ...int) interface{} {
	r := make(C128Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *C128Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case complex128:		l := s.Len() + 1
							n := make(C128Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case C128Slice:			l := s.Len() + len(v)
							n := make(C128Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []complex128:		s.Insert(i, C128Slice(v))
	default:				panic(v)
	}
}

func (s *C128Slice) Pop() (r complex128, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}