package slices

import (
	"fmt"
	"strings"
)

type F32Slice	[]float32

func (s F32Slice) Len() int							{ return len(s) }
func (s F32Slice) Cap() int							{ return cap(s) }

func (s F32Slice) At(i int) interface{}				{ return s[i] }
func (s F32Slice) Set(i int, v interface{})			{ s[i] = v.(float32) }
func (s F32Slice) Clear(i int)						{ s[i] = 0 }
func (s F32Slice) Swap(i, j int)					{ s[i], s[j] = s[j], s[i] }

func (s F32Slice) Negate(i int)						{ s[i] = -s[i] }
func (s F32Slice) Increment(i int)					{ s[i]++ }
func (s F32Slice) Decrement(i int)					{ s[i]-- }

func (s F32Slice) Add(i, j int)						{ s[i] += s[j] }
func (s F32Slice) Subtract(i, j int)				{ s[i] -= s[j] }
func (s F32Slice) Multiply(i, j int)				{ s[i] *= s[j] }
func (s F32Slice) Divide(i, j int)					{ s[i] /= s[j] }

func (s F32Slice) Sum() (r float32) {
	for x := len(s) - 1; x > -1; x-- {
		r += s[x]
	}
	return
}

func (s F32Slice) Product() (r float32) {
	r = 1
	for x := len(s) - 1; x > -1; x-- {
		r *= s[x]
	}
	return
}

func (s F32Slice) Less(i, j int) bool				{ return s[i] < s[j] }
func (s F32Slice) AtLeast(i, j int) bool			{ return s[i] <= s[j] }
func (s F32Slice) Same(i, j int) bool				{ return s[i] == s[j] }
func (s F32Slice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s F32Slice) More(i, j int) bool				{ return s[i] > s[j] }

func (s F32Slice) ZeroLessThan(i int) bool			{ return 0 < s[i] }
func (s F32Slice) ZeroAtLeast(i int) bool			{ return 0 <= s[i] }
func (s F32Slice) ZeroSameAs(i int) bool			{ return 0 == s[i] }
func (s F32Slice) ZeroAtMost(i int) bool			{ return 0 >= s[i] }
func (s F32Slice) ZeroMoreThan(i int) bool			{ return 0 > s[i] }

func (s *F32Slice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s F32Slice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s F32Slice) ZeroCompare(i int) (r int) {
	switch {
	case 0 < s[i]:			r = IS_LESS_THAN
	case 0 > s[i]:			r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *F32Slice) Cut(i, j int) {
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

func (s *F32Slice) Trim(i, j int) {
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

func (s *F32Slice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *F32Slice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case float32:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(float32) bool:		for i, v := range a {
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

func (s F32Slice) Each(f interface{}) {
	switch f := f.(type) {
	case func(float32):						for _, v := range s { f(v) }
	case func(int, float32):				for i, v := range s { f(i, v) }
	case func(interface{}, float32):		for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s F32Slice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(float32) bool:					for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, float32) bool:				for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, float32) bool:		for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s F32Slice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(float32) bool:					for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, float32) bool:				for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, float32) bool:		for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s F32Slice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s F32Slice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s F32Slice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(F32Slice, count, count))
	}
}

func (s F32Slice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case F32Slice:			copy(s[offset:], container)
	case []float32:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *F32Slice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(F32Slice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *F32Slice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *F32Slice) Expand(i, n int) {
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
		x := make(F32Slice, l, c)
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

func (s F32Slice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s F32Slice) Depth() int {
	return 0
}

func (s *F32Slice) Append(v interface{}) {
	switch v := v.(type) {
	case float32:			*s = append(*s, v)
	case F32Slice:			*s = append(*s, v...)
	case []float32:			s.Append(F32Slice(v))
	default:				panic(v)
	}
}

func (s *F32Slice) Prepend(v interface{}) {
	switch v := v.(type) {
	case float32:			l := s.Len() + 1
							n := make(F32Slice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case F32Slice:			l := s.Len() + len(v)
							n := make(F32Slice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []float32:			s.Prepend(F32Slice(v))
	default:				panic(v)
	}
}

func (s F32Slice) Repeat(count int) F32Slice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(F32Slice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s F32Slice) equal(o F32Slice) (r bool) {
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

func (s F32Slice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case F32Slice:			r = s.equal(o)
	case []float32:			r = s.equal(o)
	}
	return
}

func (s F32Slice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s F32Slice) Cdr() (t F32Slice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *F32Slice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = F32Slice{v.(float32)}
	case s.Len() == 0:		*s = append(*s, v.(float32))
	default:				(*s)[0] = v.(float32)
	}
}

func (s *F32Slice) Rplacd(v interface{}) {
	if s == nil {
		*s = F32Slice{v.(float32)}
	} else {
		ReplaceSlice := func(v F32Slice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(F32Slice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case float32:		(*s)[1] = v
							*s = (*s)[:2]
		case F32Slice:		ReplaceSlice(v)
		case []float32:		ReplaceSlice(F32Slice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s F32Slice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(float32); ok {
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

func (s F32Slice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(float32); ok {
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

func (s *F32Slice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case float32:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(float32) bool:		for i, v := range a {
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

func (s F32Slice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(float32):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, float32):				for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, float32):		for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s F32Slice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(float32)
	switch f := f.(type) {
	case float32:					for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(float32) bool:		for i, v := range s {
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

func (s *F32Slice) Replace(o interface{}) {
	switch o := o.(type) {
	case float32:			*s = F32Slice{o}
	case F32Slice:			*s = o
	case []float32:			*s = F32Slice(o)
	default:				panic(o)
	}
}

func (s F32Slice) Select(f interface{}) interface{} {
	r := make(F32Slice, 0, len(s) / 4)
	switch f := f.(type) {
	case float32:					for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(float32) bool:		for _, v := range s {
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

func (s *F32Slice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[float32] bool)
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

func (s F32Slice) Pick(n ...int) interface{} {
	r := make(F32Slice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *F32Slice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case float32:			l := s.Len() + 1
							n := make(F32Slice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case F32Slice:			l := s.Len() + len(v)
							n := make(F32Slice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []float32:			s.Insert(i, F32Slice(v))
	default:				panic(v)
	}
}

func (s *F32Slice) Pop() (r float32, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}