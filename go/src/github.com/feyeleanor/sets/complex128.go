package sets

import (
	"github.com/feyeleanor/slices"
)

type c128map	map[complex128] bool

func (m c128map) Len() int {
	return len(m)
}

func (m c128map) Member(i interface{}) (r bool) {
	if i, ok := i.(complex128); ok {
		r = m[i]
	}
	return
}

func (m c128map) Include(v interface{}) {
	switch v := v.(type) {
	case []complex128:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case complex128:
		m[v] = true
	default:
		panic(v)
	}
}

func (m c128map) Each(f interface{}) {
	switch f := f.(type) {
	case func(complex128):
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

func (m c128map) String() (t string) {
	elements := slices.C128Slice{}
	m.Each(func(v complex128) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}


type c128set struct {
	c128map
}

func C128Set(v... complex128) (r c128set) {
	r.c128map = make(c128map)
	r.Include(v)
	return
}

func (s c128set) Empty() Set {
	return C128Set()
}

func (s c128set) Intersection(o Set) Set {
	r := C128Set()
	s.Each(func(v complex128) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s c128set) Union(o Set) Set {
	r := C128Set()
	s.Each(func(v complex128) {
		r.Include(v)
	})
	o.Each(func(v complex128) {
		r.Include(v)
	})
	return r
}

func (s c128set) Difference(o Set) Set {
	r := C128Set()
	s.Each(func(v complex128) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s c128set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v complex128) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s c128set) Sum() interface{} {
	var r complex128
	s.Each(func(v complex128) {
		r += v
	})
	return r
}

func (s c128set) Product() interface{} {
	r := complex128(1)
	s.Each(func(v complex128) {
		r *= v
	})
	return r
}