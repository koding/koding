package sets

import (
	"github.com/feyeleanor/slices"
)

type u16map	map[uint16] bool

func (m u16map) Len() int {
	return len(m)
}

func (m u16map) Member(i interface{}) (r bool) {
	if i, ok := i.(uint16); ok {
		r = m[i]
	}
	return
}

func (m u16map) Include(v interface{}) {
	switch v := v.(type) {
	case []uint16:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uint16:
		m[v] = true
	default:
		panic(v)
	}
}

func (m u16map) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint16):
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


type u16set struct {
	u16map
}

func U16Set(v... uint16) (r u16set) {
	r.u16map = make(u16map)
	r.Include(v)
	return
}

func (s u16set) Empty() Set {
	return U16Set()
}

func (s u16set) String() (t string) {
	elements := slices.U16Slice{}
	s.Each(func(v uint16) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s u16set) Intersection(o Set) Set {
	r := U16Set()
	s.Each(func(v uint16) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u16set) Union(o Set) Set {
	r := U16Set()
	s.Each(func(v uint16) {
		r.Include(v)
	})
	o.Each(func(v uint16) {
		r.Include(v)
	})
	return r
}

func (s u16set) Difference(o Set) Set {
	r := U16Set()
	s.Each(func(v uint16) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u16set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uint16) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s u16set) Sum() interface{} {
	var r uint16
	s.Each(func(v uint16) {
		r += v
	})
	return r
}

func (s u16set) Product() interface{} {
	r := uint16(1)
	s.Each(func(v uint16) {
		r *= v
	})
	return r
}