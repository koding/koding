package slices

import (
	"fmt"
	"strings"
)

type ASlice		[]uintptr

func (s ASlice) Len() int							{ return len(s) }
func (s ASlice) Cap() int							{ return cap(s) }

func (s ASlice) At(i int) interface{}				{ return s[i] }
func (s ASlice) Set(i int, v interface{})			{ s[i] = v.(uintptr) }
func (s ASlice) Clear(i int)						{ s[i] = 0 }
func (s ASlice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }

func (s ASlice) Negate(i int)						{ s[i] = -s[i] }
func (s ASlice) Increment(i int)					{ s[i]++ }
func (s ASlice) Decrement(i int)					{ s[i]-- }

func (s ASlice) Add(i, j int)						{ s[i] += s[j] }
func (s ASlice) Subtract(i, j int)					{ s[i] -= s[j] }

func (s ASlice) And(i, j int)						{ s[i] &= s[j] }
func (s ASlice) Or(i, j int)						{ s[i] |= s[j] }
func (s ASlice) Xor(i, j int)						{ s[i] ^= s[j] }
func (s ASlice) Invert(i int)						{ s[i] = ^s[i] }
func (s ASlice) ShiftLeft(i, j int)					{ s[i] <<= s[j] }
func (s ASlice) ShiftRight(i, j int)				{ s[i] >>= s[j] }

func (s ASlice) Less(i, j int) bool					{ return s[i] < s[j] }
func (s ASlice) AtLeast(i, j int) bool				{ return s[i] <= s[j] }
func (s ASlice) Same(i, j int) bool					{ return s[i] == s[j] }
func (s ASlice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s ASlice) More(i, j int) bool					{ return s[i] > s[j] }
func (s ASlice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s ASlice) ZeroAtLeast(i int) bool				{ return true }
func (s ASlice) ZeroSameAs(i int) bool				{ return 0 == s[i] }
func (s ASlice) ZeroAtMost(i int) bool				{ return 0 == s[i] }
func (s ASlice) ZeroMoreThan(i int) bool			{ return false }

func (s *ASlice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s ASlice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s ASlice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *ASlice) Cut(i, j int) {
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

func (s *ASlice) Trim(i, j int) {
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

func (s *ASlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *ASlice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uintptr:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(uintptr) bool:		for i, v := range a {
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

func (s ASlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(uintptr):						for _, v := range s { f(v) }
	case func(int, uintptr):				for i, v := range s { f(i, v) }
	case func(interface{}, uintptr):		for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s ASlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(uintptr) bool:					for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, uintptr) bool:				for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, uintptr) bool:		for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ASlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(uintptr) bool:					for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, uintptr) bool:				for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, uintptr) bool:		for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ASlice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s ASlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s ASlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(ASlice, count, count))
	}
}

func (s ASlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case ASlice:			copy(s[offset:], container)
	case []uintptr:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *ASlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(ASlice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *ASlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *ASlice) Expand(i, n int) {
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
		x := make(ASlice, l, c)
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

func (s ASlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s ASlice) Depth() int {
	return 0
}

func (s *ASlice) Append(v interface{}) {
	switch v := v.(type) {
	case uintptr:			*s = append(*s, v)
	case ASlice:			*s = append(*s, v...)
	case []uintptr:			s.Append(ASlice(v))
	default:				panic(v)
	}
}

func (s *ASlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case uintptr:			l := s.Len() + 1
							n := make(ASlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case ASlice:			l := s.Len() + len(v)
							n := make(ASlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []uintptr:			s.Prepend(ASlice(v))
	default:				panic(v)
	}
}

func (s ASlice) Repeat(count int) ASlice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(ASlice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s ASlice) equal(o ASlice) (r bool) {
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

func (s ASlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case ASlice:			r = s.equal(o)
	case []uintptr:			r = s.equal(o)
	}
	return
}

func (s ASlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s ASlice) Cdr() (t ASlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *ASlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = ASlice{v.(uintptr)}
	case s.Len() == 0:		*s = append(*s, v.(uintptr))
	default:				(*s)[0] = v.(uintptr)
	}
}

func (s *ASlice) Rplacd(v interface{}) {
	if s == nil {
		*s = ASlice{v.(uintptr)}
	} else {
		ReplaceSlice := func(v ASlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(ASlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case uintptr:		(*s)[1] = v
							*s = (*s)[:2]
		case ASlice:		ReplaceSlice(v)
		case []uintptr:		ReplaceSlice(ASlice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s ASlice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(uintptr); ok {
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

func (s ASlice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(uintptr); ok {
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

func (s *ASlice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case uintptr:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(uintptr) bool:		for i, v := range a {
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

func (s ASlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(uintptr):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, uintptr):				for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, uintptr):		for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s ASlice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(uintptr)
	switch f := f.(type) {
	case uintptr:					for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(uintptr) bool:		for i, v := range s {
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

func (s *ASlice) Replace(o interface{}) {
	switch o := o.(type) {
	case uintptr:			*s = ASlice{o}
	case ASlice:			*s = o
	case []uintptr:			*s = ASlice(o)
	default:				panic(o)
	}
}

func (s ASlice) Select(f interface{}) interface{} {
	r := make(ASlice, 0, len(s) / 4)
	switch f := f.(type) {
	case uintptr:					for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(uintptr) bool:		for _, v := range s {
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

func (s *ASlice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[uintptr] bool)
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

func (s ASlice) Pick(n ...int) interface{} {
	r := make(ASlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *ASlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case uintptr:			l := s.Len() + 1
							n := make(ASlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case ASlice:			l := s.Len() + len(v)
							n := make(ASlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []uintptr:			s.Insert(i, ASlice(v))
	default:				panic(v)
	}
}

func (s *ASlice) Pop() (r uintptr, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}