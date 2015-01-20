package slices

import (
	"fmt"
	"strings"
)

type SSlice		[]string

func (s SSlice) Len() int							{ return len(s) }
func (s SSlice) Cap() int							{ return cap(s) }

func (s SSlice) At(i int) interface{}				{ return s[i] }
func (s SSlice) Set(i int, v interface{})			{ s[i] = v.(string) }
func (s SSlice) Clear(i int)						{ s[i] = "" }
func (s SSlice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }

func (s SSlice) Add(i, j int)						{ s[i] += s[j] }

func (s SSlice) Sum() {
	s.Join("")
}

func (s SSlice) Join(separator string) {
	strings.Join(([]string)(s), separator)
}

func (s SSlice) Less(i, j int) bool					{ return s[i] < s[j] }
func (s SSlice) AtLeast(i, j int) bool				{ return s[i] <= s[j] }
func (s SSlice) Same(i, j int) bool					{ return s[i] == s[j] }
func (s SSlice) AtMost(i, j int) bool				{ return s[i] >= s[j] }
func (s SSlice) More(i, j int) bool					{ return s[i] > s[j] }

func (s *SSlice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s SSlice) Compare(i, j int) (r int) {
	switch {
	case s[i] < s[j]:		r = IS_LESS_THAN
	case s[i] > s[j]:		r = IS_GREATER_THAN
	default:				r = IS_SAME_AS
	}
	return
}

func (s *SSlice) Cut(i, j int) {
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

func (s *SSlice) Trim(i, j int) {
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

func (s *SSlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		*s = a[:n - 1]
	}
}

func (s *SSlice) DeleteIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case string:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v != f {
											p++
										}
									}

	case func(string) bool:			for i, v := range a {
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

func (s SSlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(string):						for _, v := range s { f(v) }
	case func(int, string):					for i, v := range s { f(i, v) }
	case func(interface{}, string):			for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(v) }
	case func(int, interface{}):			for i, v := range s { f(i, v) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, v) }
	default:								panic(f)
	}
}

func (s SSlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(string) bool:						for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(int, string) bool:				for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, string) bool:		for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s SSlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(string) bool:						for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(int, string) bool:				for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, string) bool:		for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s SSlice) String() (t string) {
	return fmt.Sprintf("(%v)", strings.Join(([]string)(s), " "))
}

func (s SSlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s SSlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(SSlice, count, count))
	}
}

func (s SSlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case SSlice:			copy(s[offset:], container)
	case []string:			copy(s[offset:], container)
	default:				panic(container)
	}
}

func (s *SSlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)
	case capacity != cap(*s):	x := make(SSlice, length, capacity)
								copy(x, *s)
								*s = x
	default:					*s = (*s)[:length]
	}
}

func (s *SSlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *SSlice) Expand(i, n int) {
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
		x := make(SSlice, l, c)
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

func (s SSlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s SSlice) Depth() int {
	return 0
}

func (s *SSlice) Append(v interface{}) {
	switch v := v.(type) {
	case string:			*s = append(*s, v)
	case SSlice:			*s = append(*s, v...)
	case []string:			s.Append(SSlice(v))
	default:				panic(v)
	}
}

func (s *SSlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case string:			l := s.Len() + 1
							n := make(SSlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	case SSlice:			l := s.Len() + len(v)
							n := make(SSlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []string:			s.Prepend(SSlice(v))
	default:				panic(v)
	}
}

func (s SSlice) Repeat(count int) SSlice {
	length := len(s) * count
	capacity := cap(s)
	if capacity < length {
		capacity = length
	}
	destination := make(SSlice, length, capacity)
	for start, end := 0, len(s); count > 0; count-- {
		copy(destination[start:end], s)
		start = end
		end += len(s)
	}
	return destination
}

func (s *SSlice) Flatten() {
	if len(*s) > 0 {
		*s = SSlice{strings.Join(([]string)(*s), "")}
	}
}

func (s SSlice) equal(o SSlice) (r bool) {
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

func (s SSlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case SSlice:			r = s.equal(o)
	case []string:			r = s.equal(SSlice(o))
	}
	return
}

func (s SSlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0]
	}
	return
}

func (s SSlice) Cdr() (t SSlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *SSlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = SSlice{v.(string)}
	case s.Len() == 0:		*s = append(*s, v.(string))
	default:				(*s)[0] = v.(string)
	}
}

func (s *SSlice) Rplacd(v interface{}) {
	if s == nil {
		*s = SSlice{v.(string)}
	} else {
		ReplaceSlice := func(v SSlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(SSlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case string:		(*s)[1] = v
							*s = (*s)[:2]
		case SSlice:		ReplaceSlice(v)
		case []string:		ReplaceSlice(SSlice(v))
		case nil:			*s = (*s)[:1]
		default:			panic(v)
		}
	}
}

func (s SSlice) Find(v interface{}) (i int, found bool) {
	if v, ok := v.(string); ok {
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

func (s SSlice) FindN(v interface{}, n int) (i ISlice) {
	if v, ok := v.(string); ok {
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

func (s *SSlice) KeepIf(f interface{}) {
	a := *s
	p := 0
	switch f := f.(type) {
	case string:					for i, v := range a {
										if i != p {
											a[p] = v
										}
										if v == f {
											p++
										}
									}

	case func(string) bool:			for i, v := range a {
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

func (s SSlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(string):						for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, string):					for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, string):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):					for i := len(s) - 1; i > -1; i-- { f(s[i]) }
	case func(int, interface{}):			for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, interface{}):	for i := len(s) - 1; i > -1; i-- { f(i, s[i]) }
	default:								panic(f)
	}
}

func (s SSlice) ReplaceIf(f interface{}, r interface{}) {
	replacement := r.(string)
	switch f := f.(type) {
	case string:					for i, v := range s {
										if v == f {
											s[i] = replacement
										}
									}

	case func(string) bool:			for i, v := range s {
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

func (s *SSlice) Replace(o interface{}) {
	switch o := o.(type) {
	case string:			*s = SSlice{o}
	case SSlice:			*s = o
	case []string:			*s = SSlice(o)
	default:				panic(o)
	}
}

func (s SSlice) Select(f interface{}) interface{} {
	r := make(SSlice, 0, len(s) / 4)
	switch f := f.(type) {
	case string:					for _, v := range s {
										if v == f {
											r = append(r, v)
										}
									}

	case func(string) bool:			for _, v := range s {
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

func (s *SSlice) Uniq() {
	a := *s
	if len(a) > 0 {
		p := 0
		m := make(map[string] bool)
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

func (s SSlice) Pick(n ...int) interface{} {
	r := make(SSlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return r
}

func (s *SSlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case string:			l := s.Len() + 1
							n := make(SSlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	case SSlice:			l := s.Len() + len(v)
							n := make(SSlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []string:			s.Insert(i, SSlice(v))
	default:				panic(v)
	}
}

func (s *SSlice) Pop() (r string, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		*s = (*s)[:end]
		ok = true
	}
	return
}