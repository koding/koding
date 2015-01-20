package sets

import (
	"github.com/feyeleanor/slices"
)

type u32map	map[uint32] bool

func (m u32map) Len() int {
	return len(m)
}

func (m u32map) Member(i interface{}) (r bool) {
	if i, ok := i.(uint32); ok {
		r = m[i]
	}
	return
}

func (m u32map) Include(v interface{}) {
	switch v := v.(type) {
	case []uint32:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uint32:
		m[v] = true
	default:
		panic(v)
	}
}

func (m u32map) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint32):
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


type u32set struct {
	u32map
}

func U32Set(v... uint32) (r u32set) {
	r.u32map = make(u32map)
	r.Include(v)
	return
}

func (s u32set) Empty() Set {
	return U32Set()
}

func (s u32set) String() (t string) {
	elements := slices.U32Slice{}
	s.Each(func(v uint32) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s u32set) Intersection(o Set) Set {
	r := U32Set()
	s.Each(func(v uint32) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u32set) Union(o Set) Set {
	r := U32Set()
	s.Each(func(v uint32) {
		r.Include(v)
	})
	o.Each(func(v uint32) {
		r.Include(v)
	})
	return r
}

func (s u32set) Difference(o Set) Set {
	r := U32Set()
	s.Each(func(v uint32) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u32set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uint32) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s u32set) Sum() interface{} {
	var r uint32
	s.Each(func(v uint32) {
		r += v
	})
	return r
}

func (s u32set) Product() interface{} {
	r := uint32(1)
	s.Each(func(v uint32) {
		r *= v
	})
	return r
}