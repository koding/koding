package slices

import (
	"fmt"
	"github.com/feyeleanor/raw"
	"reflect"
	"strings"
)

func RWrap(i interface{}) (s RSlice) {
	switch v := i.(type) {
	case *RSlice:		s.Value = v.Value
	case RSlice:		s.Value = v.Value
	default:			if v := reflect.ValueOf(i); v.Kind() == reflect.Slice {
							if !v.CanAddr() {
								x := reflect.New(v.Type()).Elem()
								x.Set(v)
								v = x
							}
							s.Value = &v
						} else {
							panic(v.Kind())
						}
	}
	return
}

func RList(n... interface{}) (s RSlice) {
	v := reflect.ValueOf(n)
	s.Value = &v
	return
}

type RSlice	struct {
	*reflect.Value
}

func (s RSlice) MakeSlice(length, capacity int) (r RSlice) {
	n := reflect.MakeSlice(s.Type(), length, capacity)
	r.Value = &n
	return
}

func (s *RSlice) MakeAddressable() {
	n := raw.MakeAddressable(*s.Value)
	s.Value = &n
}

func (s *RSlice) setValue(v reflect.Value) {
	s.MakeAddressable()
	s.Value.Set(v)
}

func (s RSlice) release_references(i, n int) {
	zero := reflect.Zero(s.Type().Elem())
	for ; n > 0; n-- {
		s.Index(i).Set(zero)
		i++
	}
}

func (s *RSlice) SetValue(i interface{})			{ s.setValue(reflect.ValueOf(i)) }
func (s *RSlice) At(i int) interface{}				{ return s.Index(i).Interface() }
func (s *RSlice) Set(i int, value interface{})		{ s.Index(i).Set(reflect.ValueOf(value)) }
func (s *RSlice) VSet(i int, value reflect.Value)	{ s.Index(i).Set(value) }
func (s *RSlice) Clear(i int)						{ s.Index(i).Set(reflect.Zero(s.Type().Elem())) }

func (s RSlice) Swap(i, j int) {
	temp := s.Index(i).Interface()
	s.Index(i).Set(s.Index(j))
	s.Index(j).Set(reflect.ValueOf(temp))
}

func (s RSlice) RestrictTo(i, j int) {
	s.setValue(s.Slice(i, j))
}

func (s *RSlice) Cut(i, j int) {
	l := s.Len()
	if i < 0 {
		i = 0
	}
	if j > l {
		j = l
	}
	if j > i {
		n := j - i
		m := l - n
		reflect.Copy(s.Slice(i, m), s.Slice(j, l))
		s.release_references(m, n)
		s.MakeAddressable()
		s.SetLen(m)
	}
}

func (s *RSlice) Trim(i, j int) {
	l := s.Len()
	if i < 0 {
		i = 0
	}
	if j > l {
		j = l
	}
	if j > i {
		reflect.Copy(*s.Value, s.Slice(i, j))
		n := j - i
		s.release_references(n, l - n)
		s.MakeAddressable()
		s.SetLen(n)
	}
}

func (s *RSlice) Delete(i int) {
	n := s.Len()
	if i > -1 && i < n {
		l := n - 1
		reflect.Copy(s.Slice(i, l), s.Slice(i + 1, n))
		s.Clear(l)
		s.MakeAddressable()
		s.SetLen(l)
	}
}

func (s *RSlice) DeleteIf(f interface{}) {
	p := 0
	switch f := f.(type) {
	case reflect.Value:				switch f.Kind() {
									case reflect.Func:		ft := f.Type()
															if ft.NumIn() > 0 && ft.NumOut() > 0 && ft.Out(0).Kind() == reflect.Bool {
																for i := 0; i < s.Len(); i++ {
																	v := s.Index(i)
																	if i != p {
																		s.VSet(p, v)
																	}
																	if !f.Call([]reflect.Value{reflect.ValueOf(v.Interface())})[0].Bool() {
																		p++
																	}
																}
															} else {
																panic(f)
															}

									default:				for i := 0; i < s.Len(); i++ {
																v := s.Index(i)
																if i != p {
																	s.VSet(p, v)
																}
																if v.Interface() != f.Interface() {
																	p++
																}
															}
									}

	case func(reflect.Value) bool:	for i := 0; i < s.Len(); i++ {
										v := s.Index(i)
										if i != p {
											s.VSet(p, v)
										}
										if !f(v) {
											p++
										}
									}

	case func(interface{}) bool:	for i := 0; i < s.Len(); i++ {
										v := s.At(i)
										if i != p {
											s.Set(p, v)
										}
										if !f(v) {
											p++
										}
									}

	default:						s.DeleteIf(reflect.ValueOf(f))
									return
	}
	s.MakeAddressable()
	s.release_references(p, s.Len() - p)
	s.SetLen(p)
}

func (s RSlice) Each(f interface{}) {
	switch f := f.(type) {
	case func(reflect.Value):				for i := 0; i < s.Len(); i++ { f(s.Index(i)) }
	case func(int, reflect.Value):			for i := 0; i < s.Len(); i++ { f(i, s.Index(i)) }
	case func(interface{}, reflect.Value):	for i := 0; i < s.Len(); i++ { f(i, s.Index(i)) }
	case func(interface{}):					for i := 0; i < s.Len(); i++ { f(s.At(i)) }
	case func(int, interface{}):			for i := 0; i < s.Len(); i++ { f(i, s.At(i)) }
	case func(interface{}, interface{}):	for i := 0; i < s.Len(); i++ { f(i, s.At(i)) }
	default:								panic(f)
	}
}

func (s RSlice) While(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:					for i := 0; i < s.Len(); i++ {
														if !f(s.At(i)) {
															return i
														}
													}
	case func(reflect.Value) bool:					for i := 0; i < s.Len(); i++ {
														if !f(s.Index(i)) {
															return i
														}
													}
	case func(int, interface{}) bool:				for i := 0; i < s.Len(); i++ {
														if !f(i, s.At(i)) {
															return i
														}
													}
	case func(int, reflect.Value) bool:				for i := 0; i < s.Len(); i++ {
														if !f(i, s.Index(i)) {
															return i
														}
													}
	case func(interface{}, interface{}) bool:		for i := 0; i < s.Len(); i++ {
														if !f(i, s.At(i)) {
															return i
														}
													}
	case func(interface{}, reflect.Value) bool:		for i := 0; i < s.Len(); i++ {
														if !f(i, s.Index(i)) {
															return i
														}
													}
	default:										panic(f)
	}
	return s.Len()
}

func (s RSlice) Until(f interface{}) int {
	switch f := f.(type) {
	case func(interface{}) bool:				for i := 0; i < s.Len(); i++ {
													if f(s.At(i)) {
														return i
													}
												}
	case func(reflect.Value) bool:				for i := 0; i < s.Len(); i++ {
													if f(s.Index(i)) {
														return i
													}
												}
	case func(int, interface{}) bool:			for i := 0; i < s.Len(); i++ {
													if f(i, s.At(i)) {
														return i
													}
												}
	case func(int, reflect.Value) bool:			for i := 0; i < s.Len(); i++ {
													if f(i, s.Index(i)) {
														return i
													}
												}
	case func(interface{}, interface{}) bool:	for i := 0; i < s.Len(); i++ {
													if f(i, s.At(i)) {
														return i
													}
												}
	case func(interface{}, reflect.Value) bool:	for i := 0; i < s.Len(); i++ {
													if f(i, s.Index(i)) {
														return i
													}
												}
	default:									panic(f)
	}
	return s.Len()
}

func (s RSlice) String() (t string) {
	elements := []string{}
	s.Each(func( v interface{}) {
		elements = append(elements, fmt.Sprintf("%v", v))
	})
	return fmt.Sprintf("(%v)", strings.Join(elements, " "))
}

func (s RSlice) BlockCopy(destination, source, count int) {
	if destination < s.Len() {
		end := destination + count
		if end > s.Len() {
			end = s.Len()
		}
		reflect.Copy(s.Slice(destination, end), s.Slice(source, s.Len()))
	}
}

func (s RSlice) BlockClear(start, count int) {
	end := start + count
	if end > s.Len() {
		end = s.Len()
	}
	for i := start; i < end; i++ {
		s.Clear(i)
	} 
}

func (s RSlice) overwrite(offset int, source *reflect.Value) {
	if offset == 0 {
		reflect.Copy(*s.Value, *source)
	} else {
		reflect.Copy(s.Slice(offset, s.Len()), *source)
	}
}

func (s RSlice) Overwrite(offset int, source interface{}) {
	switch source := source.(type) {
	case *RSlice:			s.Overwrite(offset, *source)
	case RSlice:			s.overwrite(offset, source.Value)
	case reflect.Value:		if source.Kind() == reflect.Slice {
								s.overwrite(offset, &source)
							} else {
								s.Set(offset, source)
							}
	default:				switch v := reflect.ValueOf(source); v.Kind() {
							case reflect.Slice:		s.Overwrite(offset, source)
							default:				s.Set(offset, v)
							}
	}
}

func (s *RSlice) Reallocate(length, capacity int) {
	switch {
	case length > capacity:		s.Reallocate(capacity, capacity)

	case capacity != s.Cap():	x := s.MakeSlice(length, capacity)
								x.overwrite(0, s.Value)
								s.setValue(*x.Value)

	default:					s.setValue(s.Slice(0, length))
	}
}

func (s *RSlice) Extend(n int) {
	c := s.Cap()
	l := s.Len() + n
	if l > c {
		c = l
	}
	s.Reallocate(l, c)
}

func (s *RSlice) Expand(i, n int) {
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
		x := s.MakeSlice(l, c)
		x.Overwrite(0, s.Slice(0, i))
		if sl := s.Len(); sl > i {
			x.Overwrite(i + n, s.Slice(i, sl))
		}
		s.Value = x.Value
	} else {
		for j := l - 1; j >= i; j-- {
			s.Index(j).Set(s.Index(j - n))
		}
		s.SetLen(l)
	}
}

func (s RSlice) Depth() (c int) {
	for i := s.Len() - 1; i > -1; i-- {
		if v, ok := s.At(i).(Nested); ok {
			if r := v.Depth() + 1; r > c {
				c = r
			}
		}
	}
	return
}

func (s RSlice) Reverse() {
	end := s.Len() - 1
	for i := 0; i < end; i++ {
		s.Swap(i, end)
		end--
	}
}

func (s *RSlice) append(v... *reflect.Value) {
	for _, x := range v {
		s.setValue(reflect.Append(*s.Value, *x))
	}
}

func (s *RSlice) appendSlice(v... *reflect.Value) {
	for _, x := range v {
		s.setValue(reflect.AppendSlice(*s.Value, *x))
	}
}

func (s *RSlice) Append(v interface{}) {
	switch v := v.(type) {
	case reflect.Value:		s.append(&v)
	case RSlice:			s.appendSlice(v.Value)
	default:				switch v := reflect.ValueOf(v); v.Kind() {
							case reflect.Slice:			s.appendSlice(&v)
							default:					s.append(&v)
							}
	}
}

func (s *RSlice) Prepend(v interface{}) {
	switch v := v.(type) {
	case reflect.Value:		l := s.Len() + 1
							n := s.MakeSlice(0, l)
							switch v.Kind() {
							case reflect.Slice:		n.appendSlice(&v)
							default:				n.append(&v)
							}
							n.appendSlice(s.Value)
							s.setValue(*n.Value)

	case RSlice:			l := s.Len() + v.Len()
							n := s.MakeSlice(0, l)
							n.appendSlice(v.Value, s.Value)
							s.setValue(*n.Value)

	default:				s.Prepend(reflect.ValueOf(v))
	}
}

func (s *RSlice) Repeat(count int) *RSlice {
	length := s.Len() * count
	capacity := s.Cap()
	if capacity < length {
		capacity = length
	}
	destination := s.MakeSlice(length, capacity)
	for start, l := 0, s.Len(); count > 0; count-- {
		destination.overwrite(start, s.Value)
		start += l
	}
	return &destination
}

func (s *RSlice) Flatten() {
	if CanFlatten(s) {
		sl := s.Len()
		n := s.MakeSlice(0, sl)
		st := s.Type().Elem()
		for i := 0; i < sl; i++ {
			switch v := s.At(i).(type) {
			case RSlice:				x := &v
										x.Flatten()
										if v.Type().Elem() == st {
											n.appendSlice(x.Value)
										} else {
											n.append(x.Value)
										}

			case Flattenable:			v.Flatten()
										x := s.Index(i)
										n.append(&x)

			case reflect.Value:			if v.Kind() == reflect.Slice && v.Type().Elem() == st {
											n.appendSlice(&v)
										} else {
											n.append(&v)
										}

			default:					if v := reflect.ValueOf(v); v.Kind() == reflect.Slice && v.Type().Elem() == st {
											n.appendSlice(&v)
										} else {
											n.append(&v)
										}
			}
		}
		s.Value = n.Value
	}
}

func (s RSlice) equal(o RSlice) (r bool) {
	if s.Len() == o.Len() {
		r = true
		for i := s.Len() - 1; i > -1; i-- {
			switch v := s.At(i).(type) {
			case Equatable:		r = v.Equal(o.At(i))
			default:			r = v == o.At(i)
			}
			if !r {
				return
			}
		}
	}
	return
}

func (s RSlice) Equal(o interface{}) (r bool) {
	switch o := o.(type) {
	case RSlice:			r = s.equal(o)
	default:				if v := reflect.ValueOf(o); v.Type() == s.Type() {
								r = s.equal(RSlice{ &v })
							} else {
								r = s.Len() > 0 && s.At(0) == o
							}							
	}
	return
}

func (s RSlice) Car() (h interface{}) {
	if s.Len() > 0 {
		h = s.At(0)
	}
	return
}

func (s RSlice) Cdr() (t RSlice) {
	if sl := s.Len(); sl > 1 {
		x := s.Slice(1, sl)
		t.Value = &x
	} else {
		t = s.MakeSlice(0, 0)
	}
	return
}

func (s *RSlice) Rplaca(v interface{}) {
	switch {
	case s == nil:			s.SetValue(Slice{v})
	case s.Len() == 0:		s.Append(v)
	default:				s.Set(0, v)
	}
}

func (s *RSlice) Rplacd(v interface{}) {
	if s == nil {
		s.SetValue(Slice{v})
	} else {
		s.MakeAddressable()
		ReplaceSlice := func(v RSlice) {
			if l := v.Len(); l < s.Cap() {
				s.overwrite(1, v.Value)
				s.SetLen(l + 1)
			} else {
				l++
				n := s.MakeSlice(l, l)
				n.Index(0).Set(s.Index(0))
				n.overwrite(1, v.Value)
				s.SetValue(n)
			}
		}

		switch x := v.(type) {
		case reflect.Value:		s.Set(1, x)
								s.SetLen(2)
		case RSlice:			ReplaceSlice(x)
		case []reflect.Value:	ReplaceSlice(RWrap(x))
		case nil:				s.SetLen(1)
		default:				s.Set(1, v)
								s.SetLen(2)
		}
	}
}

func (s RSlice) Find(v interface{}) (i int, found bool) {
	for j := 0; j < s.Len(); j++ {
		if s.At(j) == v {
			i = j
			found = true
			break
		}
	}
	return
}

func (s RSlice) FindN(v interface{}, n int) (i ISlice) {
	i = make(ISlice, 0, 0)
	for j := 0; j < s.Len(); j++ {
		if s.At(j) == v {
			i = append(i, j)
			if len(i) == n {
				break
			}
		}
	}
	return
}

func (s *RSlice) KeepIf(f interface{}) {
	p := 0
	l := s.Len()
	switch f := f.(type) {
	case reflect.Value:				for i := 0; i < l; i++ {
										v := s.Index(i)
										if i != p {
											s.VSet(p, v)
										}
										if v.Interface() == f.Interface() {
											p++
										}
									}

	case func(reflect.Value) bool:	for i := 0; i < l; i++ {
										v := s.Index(i)
										if i != p {
											s.VSet(p, v)
										}
										if f(v) {
											p++
										}
									}

	case func(interface{}) bool:	for i := 0; i < l; i++ {
										v := s.Index(i)
										if i != p {
											s.VSet(p, v)
										}
										if f(v.Interface()) {
											p++
										}
									}

	default:						for i := 0; i < l; i++ {
										v := s.Index(i)
										if i != p {
											s.VSet(p, v)
										}
										if v.Interface() == f {
											p++
										}
									}
	}
	s.MakeAddressable()
	s.release_references(p, s.Len() - p)
	s.SetLen(p)
}

func (s RSlice) ReverseEach(f interface{}) {
	switch f := f.(type) {
	case func(reflect.Value):					for i := s.Len() - 1; i > -1; i-- { f(s.Index(i)) }
	case func(int, reflect.Value):				for i := s.Len() - 1; i > -1; i-- { f(i, s.Index(i)) }
	case func(interface{}, reflect.Value):		for i := s.Len() - 1; i > -1; i-- { f(i, s.Index(i)) }
	case func(interface{}):						for i := s.Len() - 1; i > -1; i-- { f(s.At(i)) }
	case func(int, interface{}):				for i := s.Len() - 1; i > -1; i-- { f(i, s.At(i)) }
	case func(interface{}, interface{}):		for i := s.Len() - 1; i > -1; i-- { f(i, s.At(i)) }
	default:									panic(f)
	}
}

func (s RSlice) ReplaceIf(f interface{}, r interface{}) {
	var replacement		reflect.Value
	var ok 				bool

	if replacement, ok = r.(reflect.Value); !ok {
		replacement = reflect.ValueOf(r)
	}
	l := s.Len()
	switch f := f.(type) {
	case reflect.Value:				fi := f.Interface()
									for i := 0; i < l; i++ {
										if s.At(i) == fi {
											s.VSet(i, replacement)
										}
									}

	case func(reflect.Value) bool:	for i := 0; i < l; i++ {
										if f(s.Index(i)) {
											s.VSet(i, replacement)
										}
									}

	case func(interface{}) bool:	for i := 0; i < l; i++ {
										if f(s.At(i)) {
											s.VSet(i, replacement)
										}
									}

	default:						for i := 0; i < l; i++ {
										if s.At(i) == f {
											s.VSet(i, replacement)
										}
									}
	}
}

func (s *RSlice) Replace(o interface{}) {
	switch o := o.(type) {
	case reflect.Value:		*s = RSlice{&o}
	case RSlice:			*s = o
	default:				*s = RWrap(o)
	}
}

func (s RSlice) Select(f interface{}) interface{} {
	l := s.Len()
	r := s.MakeSlice(0, l / 4)
	switch f := f.(type) {
	case reflect.Value:				fi := f.Interface()
									for i := 0; i < l; i++ {
										v := s.Index(i)
										if v.Interface() == fi {
											r.append(&v)
										}
									}

	case func(reflect.Value) bool:	for i := 0; i < l; i++ {
										v := s.Index(i)
										if f(v) {
											r.append(&v)
										}
									}

	case func(interface{}) bool:	for i := 0; i < l; i++ {
										v := s.Index(i)
										if f(v.Interface()) {
											r.append(&v)
										}
									}

	default:						for i := 0; i < l; i++ {
										v := s.Index(i)
										if v.Interface() == f {
											r.append(&v)
										}
									}
	}
	return r.Interface()
}

func (s *RSlice) Uniq() {
	var v	reflect.Value
	var vi	interface{}

	l := s.Len()
	if l > 0 {
		p := 0
		m := make(map[interface{}] bool)
		for i := 0; i < l; i++ {
			v = s.Index(i)
			vi = v.Interface()
			if ok := m[vi]; !ok {
				m[vi] = true
				s.VSet(p, v)
				p++
			}
		}
		s.MakeAddressable()
		s.SetLen(p)
	}
}

func (s RSlice) Pick(n ...int) interface{} {
	r := s.MakeSlice(0, len(n))
	for _, v := range n {
		n := s.Index(v)
		r.append(&n)
	}
	return r.Interface()
}

func (s *RSlice) Insert(i int, v interface{}) {
	switch v := v.(type) {
	case reflect.Value:		l := s.Len() + 1
							n := s.MakeSlice(l, l)
							reflect.Copy(*n.Value, s.Slice(0, i))
							n.Index(i).Set(v)
							reflect.Copy(n.Value.Slice(i + 1, l), s.Slice(i, l - 1))
							s.Value = n.Value

	case RSlice:			l := s.Len() + v.Len()
							n := s.MakeSlice(l, l)
							reflect.Copy(*n.Value, s.Slice(0, i))
							reflect.Copy(n.Slice(i, l), *v.Value)
							reflect.Copy(n.Slice(i + v.Len(), l), s.Slice(i, s.Len()))
							s.Value = n.Value

	case []interface{}:		s.Insert(i, RWrap(v))
	default:				s.Insert(i, reflect.ValueOf(v))
	}
}

func (s *RSlice) Pop() (r interface{}, ok bool) {
	if end := s.Len() - 1; end > -1 {
		r = s.At(end)
		s.Clear(end)
		s.SetLen(end)
		ok = true
	}
	return
}