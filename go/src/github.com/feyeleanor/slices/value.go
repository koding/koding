package slices

import (
	"fmt"
	"reflect"
	"strings"
)

func VList(n... interface{}) (s VSlice) {
	s = make(VSlice, len(n), len(n))
	for i, v := range n {
		s[i] = reflect.ValueOf(v)
	}
	return
}

type VSlice 	[]reflect.Value

func safeInterface(v reflect.Value) (r interface{}) {
	if v.IsValid() {
		r = v.Interface()
	}
	return
}

func (s VSlice) release_references(i, n int) {
	var zero reflect.Value
	for ; n > 0; n-- {
		s[i] = zero
		i++
	}
}

func (s VSlice) Len() int							{ return len(s) }
func (s VSlice) Cap() int							{ return cap(s) }
func (s VSlice) At(i int) interface{}				{ return safeInterface(s[i]) }
func (s VSlice) Set(i int, value interface{})		{ s[i] = reflect.ValueOf(value) }
func (s VSlice) VSet(i int, value reflect.Value)	{ s[i] = value }
func (s VSlice) Clear(i int)						{ s[i] = reflect.Value{} }
func (s VSlice) Swap(i, j int)						{ s[i], s[j] = s[j], s[i] }
func (s *VSlice) RestrictTo(i, j int)				{ *s = (*s)[i:j] }

func (s *VSlice) Cut(i, j int) {
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
		l -= n
		copy(a[i:], a[j:])
		a.release_references(l, n)
		*s = a[:l]
	}
}

func (s *VSlice) Trim(i, j int) {
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

func (s *VSlice) Delete(i int) {
	a := *s
	n := len(a)
	if i > -1 && i < n {
		copy(a[i:n - 1], a[i + 1:n])
		a.release_references(n - 1, 1)
		*s = a[:n - 1]
	}
}

func (s *VSlice) DeleteIf(f interface{}) {
	p := 0
	a := *s
	switch f := f.(type) {
	case reflect.Value:				for i, v := range a {
										if i != p {
											a[p] = v
										}
										if safeInterface(v) != safeInterface(f) {
											p++
										}
									}

	case func(reflect.Value) bool:	for i, v := range a {
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
										if !f(safeInterface(v)) {
											p++
										}
									}

	default:						s.DeleteIf(reflect.ValueOf(f))
									return
	}
	s.release_references(p, len(a) - p)
	*s = a[:p]
}

func (s VSlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(reflect.Value):				for _, v := range s { f(v) }
	case func(int, reflect.Value):			for i, v := range s { f(i, v) }
	case func(interface{}, reflect.Value):	for i, v := range s { f(i, v) }
	case func(interface{}):					for _, v := range s { f(safeInterface(v)) }
	case func(int, interface{}):			for i, v := range s { f(i, safeInterface(v)) }
	case func(interface{}, interface{}):	for i, v := range s { f(i, safeInterface(v)) }
	default:								panic(f)
	}
}

func (s VSlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if !f(safeInterface(v)) {
														return i
													}
												}
	case func(reflect.Value) bool:				for i, v := range s {
													if !f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if !f(i, safeInterface(v)) {
														return i
													}
												}
	case func(int, reflect.Value) bool:			for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if !f(i, safeInterface(v)) {
														return i
													}
												}
	case func(interface{}, reflect.Value) bool:	for i, v := range s {
													if !f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s VSlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i, v := range s {
													if f(safeInterface(v)) {
														return i
													}
												}
	case func(reflect.Value) bool:				for i, v := range s {
													if f(v) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i, v := range s {
													if f(i, safeInterface(v)) {
														return i
													}
												}
	case func(int, reflect.Value) bool:			for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i, v := range s {
													if f(i, safeInterface(v)) {
														return i
													}
												}
	case func(interface{}, reflect.Value) bool:	for i, v := range s {
													if f(i, v) {
														return i
													}
												}
	default:									panic(f)
	}
	return len(s)
}

func (s VSlice) String() (t string) {
	elements := []string{}
	for _, v := range s {
		elements = append(elements, fmt.Sprintf("%v", safeInterface(v)))
	}
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s VSlice) BlockCopy(destination, source, count int) {
	if destination < len(s) {
		if end := destination + count; end >= len(s) {
			copy(s[destination:], s[source:])
		} else {
			copy(s[destination : end], s[source:])
		}
	}
}

func (s VSlice) BlockClear(start, count int) {
	if start > -1 && start < len(s) {
		copy(s[start:], make(VSlice, count, count))
	}
}

func (s VSlice) Overwrite(offset int, container interface{}) {
	switch container := container.(type) {
	case VSlice:			copy(s[offset:], container)
	case []reflect.Value:	s.Overwrite(offset, VSlice(container))
	default:				panic(container)
	}
}

func (s *VSlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)

	case capacity != s.Cap():	x := make(VSlice, length, capacity)
								copy(x, *s)
								*s = x

	default:					*s = (*s)[:length]
	}
}

func (s *VSlice) Extend(n int) {
	c := cap(*s)
	l := len(*s) + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *VSlice) Expand(i, n int) {
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
		x := make(VSlice, l, c)
		copy(x, (*s)[0:i])
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

func (s VSlice) Depth() (c int) {
	for _, v := range s {
		if vi, ok := safeInterface(v).(Nested); ok {
			if r := vi.Depth() + 1; r > c {
				c = r
			}
		} else if v.Kind() == reflect.Slice {
			if c == 0 {
				c = 1
			}
		}
	}
	return
}

func (s VSlice) Reverse() {
	end := len(s) - 1
	for i := 0; i < end; i++ {
		s[i], s[end] = s[end], s[i]
		end--
	}
}

func (s *VSlice) Append(v interface{}) {
	switch v := v.(type) {
	case VSlice:			l := len(*s) + len(v)
							n := make(VSlice, l, l)
							copy(n, *s)
							copy(n[len(*s):], v)
							*s = n

	case []reflect.Value:	s.Append(VSlice(v))

	case reflect.Value:		*s = append(*s, v)

	default:				*s = append(*s, reflect.ValueOf(v))
	}
}

func (s *VSlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case VSlice:			l := len(*s) + len(v)
							n := make(VSlice, l, l)
							copy(n, v)
							copy(n[len(v):], *s)
							*s = n

	case []reflect.Value:	s.Prepend(VSlice(v))

	case reflect.Value:		l := len(*s) + 1
							n := make(VSlice, l, l)
							n[0] = v
							copy(n[1:], *s)
							*s = n

	default:				l := len(*s) + 1
							n := make(VSlice, l, l)
							n[0] = reflect.ValueOf(v)
							copy(n[1:], *s)
							*s = n
	}	
}

func (s *VSlice) AppendSlice(v interface{}) {
	if n, ok := v.(reflect.Value); ok {
		*s = append(*s, n)
	} else {
		*s = append(*s, reflect.ValueOf(v))
	}
}

func (s *VSlice) PrependSlice(v interface{}) {
	l := len(*s) + 1
	n := make(VSlice, l, l)
	if x, ok := v.(reflect.Value); ok {
		n[0] = x
	} else {
		n[0] = reflect.ValueOf(v)
	}
	copy(n[1:], *s)
	*s = n
}

func (s *VSlice) Repeat(count int) VSlice {
	ls := len(*s)
	length := ls * count
	capacity := cap(*s)
	if capacity < length {
		capacity = length
	}
	destination := make(VSlice, length, capacity)
	for start, end := 0, ls; count > 0; count-- {
		copy(destination[start:end], *s)
		start = end
		end += ls
	}
	return destination
}

func (s *VSlice) Flatten() {
	if s != nil {
		sl := len(*s)
		n := make(VSlice, 0, sl)
		for i, v := range *s {
			switch v := safeInterface(v).(type) {
			case VSlice:			(&v).Flatten()
									n = append(n, v...)

			case []reflect.Value:	r := VSlice(v)
									r.Flatten()
									n = append(n, r...)

			default:				if v, ok := v.(Flattenable); ok {
										v.Flatten()
									}
									if (*s)[i].Kind() == reflect.Slice {
										r := RSlice{&(*s)[i]}
										r.Flatten()
										ln := len(n)
										l := r.Len() + ln
										m := make(VSlice, l, l)
										copy(m, n)
										for i := r.Len() - 1; i > -1; i-- {
											m[i + ln] = r.Index(i)
										}
										n = m
									} else {
										n = append(n, (*s)[i])
									}
			}
		}
		*s = n
	}
}

func (s VSlice) equal(o VSlice) (r bool) {
	if len(s) == len(o) {
		r = true
		defer func() {
			if x := recover(); x != nil {
				r = false
			}
		}()
		for i, v := range s {
			oi := safeInterface(o[i])
			switch v := safeInterface(v).(type) {
			case Equatable:		r = v.Equal(oi)
			default:			r = v == oi
			}
			if !r {
				return
			}
		}
	}
	return
}

func (s VSlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case VSlice:			r = s.equal(o)
	case []reflect.Value:	r = s.equal(o)
	}
	return
}

func (s VSlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s[0].Interface()
	}
	return
}

func (s VSlice) Cdr() (t VSlice) {
	if s.Len() > 1 {
		t = s[1:]
	}
	return
}

func (s *VSlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			*s = VList(v)
	case s.Len() == 0:		if n, ok := v.(reflect.Value); ok {
								*s = append(*s, n)
							} else {
								*s = append(*s, reflect.ValueOf(n))
							}
							
	default:				if n, ok := v.(reflect.Value); ok {
								(*s)[0] = n
							} else {
								(*s)[0] = reflect.ValueOf(v)
							}
	}
}

func (s *VSlice) Rplacd(v interface{}) {
	if s == nil {
		if _, ok := v.(reflect.Value); ok {
			*s = VList(v)
		} else {
			*s = VList(reflect.ValueOf(v))
		}
	} else {
		ReplaceSlice := func(v VSlice) {
			if l := len(v); l < cap(*s) {
				copy((*s)[1:], v)
				*s = (*s)[:l + 1]
			} else {
				l++
				n := make(VSlice, l, l)
				copy(n, (*s)[:1])
				copy(n[1:], v)
				*s = n
			}
		}

		switch v := v.(type) {
		case reflect.Value:		(*s)[1] = v
								*s = (*s)[:2]
		case VSlice:			ReplaceSlice(v)
		case []reflect.Value:	ReplaceSlice(VSlice(v))
		case nil:				*s = (*s)[:1]
		default:				(*s)[1] = reflect.ValueOf(v)
								*s = (*s)[:2]
		}
	}
}

func (s VSlice) Find(x interface{}) (i int, found bool) {
	for j, v := range s {
		if safeInterface(v) == x {
			i = j
			found = true
			break
		}
	}
	return
}

func (s VSlice) FindN(x interface{}, n int) (i ISlice) {
	i = make(ISlice, 0, 0)
	for j, v := range s {
		if safeInterface(v) == x {
			i = append(i, j)
			if len(i) == n {
				break
			}
		}
	}
	return
}

func (s *VSlice) KeepIf(f interface{}) {
	p := 0
	a := *s
	switch f := f.(type) {
	case reflect.Value:				for i, v := range a {
										if i != p {
											a[p] = v
										}
										if safeInterface(v) == safeInterface(f) {
											p++
										}
									}

	case func(reflect.Value) bool:	for i, v := range a {
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
										if f(safeInterface(v)) {
											p++
										}
									}

	default:						for i, v := range a {
										if i != p {
											a[p] = v
										}
										if safeInterface(v) == f {
											p++
										}
									}
	}
	s.release_references(p, len(a) - p)
	*s = a[:p]
}

func (s VSlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(reflect.Value):					for i := s.Len() - 1; i > -1; i-- { f(s[i]) }
	case func(int, reflect.Value):				for i := s.Len() - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}, reflect.Value):		for i := s.Len() - 1; i > -1; i-- { f(i, s[i]) }
	case func(interface{}):						for i := s.Len() - 1; i > -1; i-- { f(safeInterface(s[i])) }
	case func(int, interface{}):				for i := s.Len() - 1; i > -1; i-- { f(i, safeInterface(s[i])) }
	case func(interface{}, interface{}):		for i := s.Len() - 1; i > -1; i-- { f(i, safeInterface(s[i])) }
	default:									panic(f)
	}
}

func (s VSlice) ReplaceIf(f interface{}, r interface{}) {
	var replacement		reflect.Value
	var ok 				bool

	if replacement, ok = r.(reflect.Value); !ok {
		replacement = reflect.ValueOf(r)
	}
	switch f := f.(type) {
	case reflect.Value:				fi := safeInterface(f)
									for i, v := range s {
										if safeInterface(v) == fi {
											s[i] = replacement
										}
									}

	case func(reflect.Value) bool:	for i, v := range s {
										if f(v) {
											s[i] = replacement
										}
									}

	case func(interface{}) bool:	for i, v := range s {
										if f(safeInterface(v)) {
											s[i] = replacement
										}
									}

	default:						for i, v := range s {
										if safeInterface(v) == f {
											s[i] = replacement
										}
									}
	}
}

func (s *VSlice) Replace(o interface{}) {
	switch o := o.(type) {
	case VSlice:			*s = o
	case []reflect.Value:	*s = VSlice(o)
	case []interface{}:		*s = VList(o...)
	case reflect.Value:		*s = VSlice{ o }

	default:				if v := reflect.ValueOf(o); v.Kind() == reflect.Slice {
								vl := v.Len()
								n := make(VSlice, vl, vl)
								for i := 0; i < vl; i++ {
									n[i] = v.Index(i)
								}
								*s = n
							} else {
								*s = VSlice{ v }
							}
	}
}

func (s VSlice) Select(f interface{}) (r VSlice) {
	l := s.Len()
	r = make(VSlice, 0, l / 4)
	switch f := f.(type) {
	case reflect.Value:				fi := safeInterface(f)
									for _, v := range s {
										if safeInterface(v) == fi {
											r = append(r, v)
										}
									}

	case func(reflect.Value) bool:	for _, v := range s {
										if f(v) {
											r = append(r, v)
										}
									}

	case func(interface{}) bool:	for _, v := range s {
										if f(safeInterface(v)) {
											r = append(r, v)
										}
									}

	default:						for _, v := range s {
										if safeInterface(v) == f {
											r = append(r, v)
										}
									}
	}
	return
}

func (s *VSlice) Uniq() {
	l := s.Len()
	if l > 0 {
		p := 0
		m := make(map[interface{}] bool)
		a := *s
		for _, v := range a {
			vi := safeInterface(v)
			if ok := m[vi]; !ok {
				m[vi] = true
				a[p] = v
				p++
			}
		}
		*s = a[:p]
	}
}

func (s VSlice) Pick(n ...int) (r VSlice) {
	r = make(VSlice, 0, len(n))
	for _, v := range n {
		r = append(r, s[v])
	}
	return
}

func (s *VSlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case VSlice:			l := s.Len() + len(v)
							n := make(VSlice, l, l)
							copy(n, (*s)[:i])
							copy(n[i:], v)
							copy(n[i + len(v):], (*s)[i:])
							*s = n

	case []reflect.Value:	s.Insert(i, VSlice(v))

	case reflect.Value:		l := len(*s) + 1
							n := make(VSlice, l, l)
							copy(n, (*s)[:i])
							n[i] = v
							copy(n[i + 1:], (*s)[i:])
							*s = n

	default:				l := len(*s) + 1
							n := make(VSlice, l, l)
							copy(n, (*s)[:i])
							n[i] = reflect.ValueOf(v)
							copy(n[i + 1:], (*s)[i:])
							*s = n
	}
}

func (s *VSlice) Pop() (r interface{}, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = (*s)[end]
		s.release_references(end, 1)
		*s = (*s)[:end]
		ok = true
	}
	return
}