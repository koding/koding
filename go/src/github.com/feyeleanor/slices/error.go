package slices

import (
	"fmt"
	"strings"
)

type ESlice		[]error

func (s ESlice) release_references(i, n int) {
	var zero error
	for ; n > 0; n-- {
		s[i] = zero
		i++
	}
}

func (s ESlice) Len() int					{ return len(s) }
func (s ESlice) Cap() int					{ return cap(s) }
func (s ESlice) At(i int) interface{}		{ return s[i] }
func (s ESlice) Set(i int, v interface{})	{ s[i] = v.(error) }
func (s ESlice) Clear(i int)				{ s[i] = nil }
func (s ESlice) Swap(i, j int)				{ s[i], s[j] = s[j], s[i] }
func (s *ESlice) RestrictTo(i, j int)		{ *s = (*s)[i:j] }

func (s *ESlice) Cut(i, j int) {
	a := *s
	l := len(a)
	if i < 0 {
		i = 0
	}
	if j > l {
		j = l
	}
	if j > i {
		n := j - i
		copy(a[i:], a[j:l])
		a.release_references(l - n, n)
		*s = a[:l - n]
	}
}

func (s *ESlice) Trim(i, j int) {
	a := *s
	l := len(a)
	if i < 0 {
		i = 0
	}
	if j > l {
		j = l
	}
	if j > i {
		copy(a, a[i:j])
		n := j - i
		a.release_references(n, l - n)
		*s = a[:n]
	}
}

func (s *ESlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		end := n - 1
		copy(a[i:end], a[i + 1:n])
		a.release_references(end, 1)
		*s = a[:end]
	}
}

func (s *ESlice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case error:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(error) bool:			for i, v := range a {
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
	s.release_references(p, len(a) - p)
	*s = a[:p]
}

func (s ESlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(error):							for _, v := range s { f(v) }
	case func(int, error):						for i, v := range s { f(i, v) }
	case func(interface{}, error):				for i, v := range s { f(i, v) }
	case func(interface{}):						for _, v := range s { f(v) }
	case func(int, interface{}):				for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):		for i, v := range s { f(i, v) }
	default:									panic(f)
	}
}

func (s ESlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(error) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, error) bool:					for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, error) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ESlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(error) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, error) bool:					for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, error) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s ESlice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", v))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s ESlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s ESlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(ESlice, count, count))
	}
}

func (s ESlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case ESlice:				copy(s[offset:], container)
	case []error:				copy(s[offset:], container)
	default:					panic(container)
	}
}

func (s *ESlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(ESlice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *ESlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *ESlice) Expand(i, n int) {
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
		x := make(ESlice, l, c)
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

func (s ESlice) Depth() (c int) {
	for _, v := range s {
		if v, ok := v.(Nested); ok {
			if r := v.Depth() + 1; r > c {
				c = r
			}
		}
	}
	return
}

func (s ESlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s *ESlice) Append(v interface{}) {
	switch v := v.(type) {
	case error:				*s = append(*s, v)
	case ESlice:			*s = append(*s, v...)
	case []error:			*s = append(*s, v...)
	default:				*s = append(*s, v.(error))
	}
}

func (s *ESlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case error:				l := s.Len() + 1
							n := make(ESlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n
	case ESlice:			l := s.Len() + len(v)
							n := make(ESlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []error:			s.Prepend(ESlice(v))
	default:				panic(v)
	}
}

func (s ESlice) Repeat(count int) ESlice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(ESlice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s ESlice) equal(o ESlice) (r bool) {
	if len(s) == len(o) {
		r = true
		for i, v := range s {
			switch v := v.(type) {
			case Equatable:		r = v.Equal(o[i])
			default:			r = v == o[i]
			}
			if !r {
				return
			}
		}
	}
	return
}

func (s ESlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case ESlice:			r = s.equal(o)
	case []error:			r = s.equal(o)
	}
	return
}

func (s ESlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s ESlice) Cdr() (t ESlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *ESlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = ESlice{v.(error)}
	case s.Len() == 0:		*s = append(*s, v.(error))
	default:				(*s)[0] = v.(error)
	}
}

func (s *ESlice) Rplacd(v interface{}) {
	if s == nil {
		*s = ESlice{v.(error)}
	} else {
		ReplaceSlice := func(v ESlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(ESlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case *ESlice:			ReplaceSlice(*v)
		case ESlice:			ReplaceSlice(v)
		case *[]error:			ReplaceSlice(ESlice(*v))
		case []error:			ReplaceSlice(ESlice(v))
		case nil:				*s = (*s)[:1]
		default:				(*s)[1] = v.(error)
								*s = (*s)[:2]
		}
	}
}

func (s ESlice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(error); ok {
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

func (s ESlice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(error); ok {
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

func (s *ESlice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case error:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(error) bool:			for i, v := range a {
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
	s.release_references(p, len(a) - p)
	*s = a[:p]
}

func (s ESlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(error):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, error):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, error):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s ESlice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(error)
	switch f := f.(type) {
	case error:						for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(error) bool:			for i, v := range s {
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

func (s *ESlice) Replace(o interface{}) {
	switch o := o.(type) {
	case error:				*s = ESlice{o}
	case ESlice:			*s = o
	case []error:			*s = ESlice(o)
	default:				panic(o)
	}
}

func (s ESlice) Select(f interface{}) interface{} {
	r := make(ESlice, 0, len(s) / 4)
	switch f := f.(type) {
	case error:						for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(error) bool:			for _, v := range s {
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

func (s *ESlice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[error] bool)
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

func (s ESlice) Pick(n ...int) interface{} {
	r := make(ESlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *ESlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case error:				l := s.Len() + 1
							n := make(ESlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case ESlice:			l := s.Len() + len(v)
							n := make(ESlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []error:			s.Insert(i, ESlice(v))

	default:				panic(v)
	}
}

func (s *ESlice) Pop() (r error, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		s.Clear(end)
		*s = (*s)[:end]
		ok = true
	}
	return
}