package sets

import (
	"github.com/feyeleanor/slices"
)

type i16map	map[int16] bool

func (m i16map) Len() int {
	return len(m)
}

func (m i16map) Member(i interface{}) (r bool) {
	if i, ok := i.(int16); ok {
		r = m[i]
	}
	return
}

func (m i16map) Include(v interface{}) {
	switch v := v.(type) {
	case []int16:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case int16:
		m[v] = true
	default:
		panic(v)
	}
}

func (m i16map) Each(f interface{}) {
	switch f := f.(type) {
	case func(int16):
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


type i16set struct {
	i16map
}

func I16Set(v... int16) (r i16set) {
	r.i16map = make(i16map)
	r.Include(v)
	return
}

func (s i16set) Empty() Set {
	return I16Set()
}

func (s i16set) String() (t string) {
	elements := slices.I16Slice{}
	s.Each(func(v int16) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s i16set) Intersection(o Set) Set {
	r := I16Set()
	s.Each(func(v int16) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i16set) Union(o Set) Set {
	r := I16Set()
	s.Each(func(v int16) {
		r.Include(v)
	})
	o.Each(func(v int16) {
		r.Include(v)
	})
	return r
}

func (s i16set) Difference(o Set) Set {
	r := I16Set()
	s.Each(func(v int16) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i16set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v int16) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s i16set) Sum() interface{} {
	var r int16
	s.Each(func(v int16) {
		r += v
	})
	return r
}

func (s i16set) Product() interface{} {
	r := int16(1)
	s.Each(func(v int16) {
		r *= v
	})
	return r
}