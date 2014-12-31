package sets

import (
	"github.com/feyeleanor/slices"
)

type u64map	map[uint64] bool

func (m u64map) Len() int {
	return len(m)
}

func (m u64map) Member(i interface{}) (r bool) {
	if i, ok := i.(uint64); ok {
		r = m[i]
	}
	return
}

func (m u64map) Include(v interface{}) {
	switch v := v.(type) {
	case []uint64:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uint64:
		m[v] = true
	default:
		panic(v)
	}
}

func (m u64map) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint64):
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


type u64set struct {
	u64map
}

func U64Set(v... uint64) (r u64set) {
	r.u64map = make(u64map)
	r.Include(v)
	return
}

func (s u64set) Empty() Set {
	return U64Set()
}

func (s u64set) String() (t string) {
	elements := slices.U64Slice{}
	s.Each(func(v uint64) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s u64set) Intersection(o Set) Set {
	r := U64Set()
	s.Each(func(v uint64) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u64set) Union(o Set) Set {
	r := U64Set()
	s.Each(func(v uint64) {
		r.Include(v)
	})
	o.Each(func(v uint64) {
		r.Include(v)
	})
	return r
}

func (s u64set) Difference(o Set) Set {
	r := U64Set()
	s.Each(func(v uint64) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s u64set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uint64) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s u64set) Sum() interface{} {
	var r uint64
	s.Each(func(v uint64) {
		r += v
	})
	return r
}

func (s u64set) Product() interface{} {
	r := uint64(1)
	s.Each(func(v uint64) {
		r *= v
	})
	return r
}