package sets

import (
	"github.com/feyeleanor/slices"
)

type i8map	map[int8] bool

func (m i8map) Len() int {
	return len(m)
}

func (m i8map) Member(i interface{}) (r bool) {
	if i, ok := i.(int8); ok {
		r = m[i]
	}
	return
}

func (m i8map) Include(v interface{}) {
	switch v := v.(type) {
	case []int8:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case int8:
		m[v] = true
	default:
		panic(v)
	}
}

func (m i8map) Each(f interface{}) {
	switch f := f.(type) {
	case func(int8):
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


type i8set struct {
	i8map
}

func I8Set(v... int8) (r i8set) {
	r.i8map = make(i8map)
	r.Include(v)
	return
}

func (s i8set) Empty() Set {
	return I8Set()
}

func (s i8set) String() (t string) {
	elements := slices.I8Slice{}
	s.Each(func(v int8) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s i8set) Intersection(o Set) Set {
	r := I8Set()
	s.Each(func(v int8) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i8set) Union(o Set) Set {
	r := I8Set()
	s.Each(func(v int8) {
		r.Include(v)
	})
	o.Each(func(v int8) {
		r.Include(v)
	})
	return r
}

func (s i8set) Difference(o Set) Set {
	r := I8Set()
	s.Each(func(v int8) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i8set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v int8) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s i8set) Sum() interface{} {
	var r int8
	s.Each(func(v int8) {
		r += v
	})
	return r
}

func (s i8set) Product() interface{} {
	r := int8(1)
	s.Each(func(v int8) {
		r *= v
	})
	return r
}