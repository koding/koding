package sets

import (
	"github.com/feyeleanor/slices"
)

type i32map	map[int32] bool

func (m i32map) Len() int {
	return len(m)
}

func (m i32map) Member(i interface{}) (r bool) {
	if i, ok := i.(int32); ok {
		r = m[i]
	}
	return
}

func (m i32map) Include(v interface{}) {
	switch v := v.(type) {
	case []int32:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case int32:
		m[v] = true
	default:
		panic(v)
	}
}

func (m i32map) Each(f interface{}) {
	switch f := f.(type) {
	case func(int32):
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


type i32set struct {
	i32map
}

func I32Set(v... int32) (r i32set) {
	r.i32map = make(i32map)
	r.Include(v)
	return
}

func (s i32set) Empty() Set {
	return I32Set()
}

func (s i32set) String() (t string) {
	elements := slices.I32Slice{}
	s.Each(func(v int32) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s i32set) Intersection(o Set) Set {
	r := I32Set()
	s.Each(func(v int32) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i32set) Union(o Set) Set {
	r := I32Set()
	s.Each(func(v int32) {
		r.Include(v)
	})
	o.Each(func(v int32) {
		r.Include(v)
	})
	return r
}

func (s i32set) Difference(o Set) Set {
	r := I32Set()
	s.Each(func(v int32) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i32set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v int32) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s i32set) Sum() interface{} {
	var r int32
	s.Each(func(v int32) {
		r += v
	})
	return r
}

func (s i32set) Product() interface{} {
	r := int32(1)
	s.Each(func(v int32) {
		r *= v
	})
	return r
}
