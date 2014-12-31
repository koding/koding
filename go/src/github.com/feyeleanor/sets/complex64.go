package sets

import (
	"github.com/feyeleanor/slices"
)

type c64map	map[complex64] bool

func (m c64map) Len() int {
	return len(m)
}

func (m c64map) Member(i interface{}) (r bool) {
	if i, ok := i.(complex64); ok {
		r = m[i]
	}
	return
}

func (m c64map) Include(v interface{}) {
	switch v := v.(type) {
	case []complex64:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case complex64:
		m[v] = true
	default:
		panic(v)
	}
}

func (m c64map) Each(f interface{}) {
	switch f := f.(type) {
	case func(complex64):
		for k, v := range m {
			if v {
				f(k)
			}
		}
	case func(interface{}):
		for k, v := range m {
			if v {
				f(k)
			}
		}
	}
}

func (m c64map) String() (t string) {
	elements := slices.C64Slice{}
	m.Each(func(v complex64) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}


type c64set struct {
	c64map
}

func C64Set(v... complex64) (r c64set) {
	r.c64map = make(c64map)
	r.Include(v)
	return
}

func (s c64set) Empty() Set {
	return C64Set()
}

func (s c64set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v complex64) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s c64set) Sum() interface{} {
	var r complex64
	s.Each(func(v complex64) {
		r += v
	})
	return r
}

func (s c64set) Product() interface{} {
	r := complex64(1)
	s.Each(func(v complex64) {
		r *= v
	})
	return r
}