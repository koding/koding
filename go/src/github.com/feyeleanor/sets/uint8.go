package sets

import (
	"github.com/feyeleanor/slices"
)

type u8map	map[uint8] bool

func (m u8map) Len() int {
	return len(m)
}

func (m u8map) Member(i interface{}) (r bool) {
	if i, ok := i.(uint8); ok {
		r = m[i]
	}
	return
}

func (m u8map) Include(v interface{}) {
	switch v := v.(type) {
	case []uint8:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uint8:
		m[v] = true
	default:
		panic(v)
	}
}

func (m u8map) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint8):
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


type u8set struct {
	u8map
}

func U8Set(v... uint8) (r u8set) {
	r.u8map = make(u8map)
	r.Include(v)
	return
}

func (s u8set) Empty() Set {
	return U8Set()
}

func (s u8set) String() (t string) {
	elements := slices.U8Slice{}
	s.Each(func(v uint8) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s u8set) Intersection(o Set) Set {
	r := U8Set()
	s.Each(func(v uint8) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u8set) Union(o Set) Set {
	r := U8Set()
	s.Each(func(v uint8) {
		r.Include(v)
	})
	o.Each(func(v uint8) {
		r.Include(v)
	})
	return r
}

func (s u8set) Difference(o Set) Set {
	r := U8Set()
	s.Each(func(v uint8) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u8set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uint8) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s u8set) Sum() interface{} {
	var r uint8
	s.Each(func(v uint8) {
		r += v
	})
	return r
}

func (s u8set) Product() interface{} {
	r := uint8(1)
	s.Each(func(v uint8) {
		r *= v
	})
	return r
}