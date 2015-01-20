package slices

import (
	"fmt"
	"strings"
)

type F64Slice	[]float64

func (s F64Slice) Len() int							{ return len(s) }
func (s F64Slice) Cap() int							{ return cap(s) }

func (s F64Slice) At(i int) interface{}				{ return s[i] }
func (s F64Slice) Set(i int, v interface{})			{ s[i] = v.(float64) }
func (s F64Slice) Clear(i int)						{ s[i] = 0 }
func (s F64Slice) Swap(i, j int)					{ s[i], s[j] = s[j], s[i] }

func (s F64Slice) Negate(i int)						{ s[i] = -s[i] }
func (s F64Slice) Increment(i int)					{ s[i]++ }
func (s F64Slice) Decrement(i int)					{ s[i]-- }

func (s F64Slice) Add(i, j int)						{ s[i] += s[j] }
func (s F64Slice) Subtract(i, j int)				{ s[i] -= s[j] }
func (s F64Slice) Multiply(i, j int)				{ s[i] *= s[j] }
func (s F64Slice) Divide(i, j int)					{ s[i] /= s[j] }

func (s F64Slice) Sum() (r float64) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s F64Slice) Product() (r float64) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s F64Slice) Less(i, j int) bool				{ return s[i] < s[j] }
func (s F64Slice) AtLeast(i, j int) bool			{ return s[i] <= s[j] }
func (s F64Slice) Same(i, j int) bool				{ return s[i] == s[j] }
func (s F64Slice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s F64Slice) More(i, j int) bool				{ return s[i] > s[j] }

func (s F64Slice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s F64Slice) ZeroAtLeast(i int) bool			{ return 0 <= s[i] }
func (s F64Slice) ZeroSameAs(i int) bool			{ return 0 == s[i] }
func (s F64Slice) ZeroAtMost(i int) bool			{ return 0 >= s[i] }
func (s F64Slice) ZeroMoreThan(i int) bool			{ return 0 > s[i] }

func (s *F64Slice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s F64Slice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s F64Slice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *F64Slice) Cut(i, j int) {
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

func (s *F64Slice) Trim(i, j int) {
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

func (s *F64Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *F64Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case float64:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(float64) bool:		for i, v := range a {
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

func (s F64Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(float64):						for _, v := range s { f(v) }
	case func(int, float64):				for i, v := range s { f(i, v) }
	case func(interface{}, float64):		for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s F64Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(float64) bool:					for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, float64) bool:				for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, float64) bool:		for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s F64Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(float64) bool:					for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, float64) bool:				for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, float64) bool:		for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s F64Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s F64Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s F64Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(F64Slice, count, count))
	}
}

func (s F64Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case F64Slice:			copy(s[offset:], container)
	case []float64:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *F64Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(F64Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *F64Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *F64Slice) Expand(i, n int) {
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
		x := make(F64Slice, l, c)
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

func (s F64Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s F64Slice) Depth() int {
	return 0
}

func (s *F64Slice) Append(v interface{}) {
	switch v := v.(type) {
	case float64:			*s = append(*s, v)
	case F64Slice:			*s = append(*s, v...)
	case []float64:			s.Append(F64Slice(v))
	default:				panic(v)
	}
}

func (s *F64Slice) Prepend(v interface{}) {
	switch v := v.(type) {
	case float64:			l := s.Len() + 1
							n := make(F64Slice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case F64Slice:			l := s.Len() + len(v)
							n := make(F64Slice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []float64:			s.Prepend(F64Slice(v))
	default:				panic(v)
	}
}

func (s F64Slice) Repeat(count int) F64Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(F64Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s F64Slice) equal(o F64Slice) (r bool) {
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

func (s F64Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case F64Slice:			r = s.equal(o)
	case []float64:			r = s.equal(o)
	}
	return
}

func (s F64Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s F64Slice) Cdr() (t F64Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *F64Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = F64Slice{v.(float64)}
	case s.Len() == 0:		*s = append(*s, v.(float64))
	default:				(*s)[0] = v.(float64)
	}
}

func (s *F64Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = F64Slice{v.(float64)}
	} else {
		ReplaceSlice := func(v F64Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(F64Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case float64:		(*s)[1] = v
							*s = (*s)[:2]
		case F64Slice:		ReplaceSlice(v)
		case []float64:		ReplaceSlice(F64Slice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s F64Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(float64); ok {
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

func (s F64Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(float64); ok {
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

func (s *F64Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case float64:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(float64) bool:		for i, v := range a {
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

func (s F64Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(float64):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, float64):				for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, float64):		for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s F64Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(float64)
	switch f := f.(type) {
	case float64:					for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(float64) bool:		for i, v := range s {
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

func (s *F64Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case float64:			*s = F64Slice{o}
	case F64Slice:			*s = o
	case []float64:			*s = F64Slice(o)
	default:				panic(o)
	}
}

func (s F64Slice) Select(f interface{}) interface{} {
	r := make(F64Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case float64:					for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(float64) bool:		for _, v := range s {
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

func (s *F64Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[float64] bool)
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

func (s F64Slice) Pick(n ...int) interface{} {
	r := make(F64Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *F64Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case float64:			l := s.Len() + 1
							n := make(F64Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case F64Slice:			l := s.Len() + len(v)
							n := make(F64Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []float64:			s.Insert(i, F64Slice(v))
	default:				panic(v)
	}
}

func (s *F64Slice) Pop() (r float64, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}