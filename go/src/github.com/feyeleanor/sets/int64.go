package sets

import (
	"github.com/feyeleanor/slices"
)

type i64map	map[int64] bool

func (m i64map) Len() int {
	return len(m)
}

func (m i64map) Member(i interface{}) (r bool) {
	if i, ok := i.(int64); ok {
		r = m[i]
	}
	return
}

func (m i64map) Include(v interface{}) {
	switch v := v.(type) {
	case []int64:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case int64:
		m[v] = true
	default:
		panic(v)
	}
}

func (m i64map) Each(f interface{}) {
	switch f := f.(type) {
	case func(int64):
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
	default:
		panic(f)
	}
}


type i64set struct {
	i64map
}

func I64Set(v... int64) (r i64set) {
	r.i64map = make(i64map)
	r.Include(v)
	return
}

func (s i64set) Empty() Set {
	return I64Set()
}

func (s i64set) String() (t string) {
	elements := slices.I64Slice{}
	s.Each(func(v int64) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s i64set) Intersection(o Set) Set {
	r := I64Set()
	s.Each(func(v int64) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i64set) Union(o Set) Set {
	r := I64Set()
	s.Each(func(v int64) {
		r.Include(v)
	})
	o.Each(func(v int64) {
		r.Include(v)
	})
	return r
}

func (s i64set) Difference(o Set) Set {
	r := I64Set()
	s.Each(func(v int64) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s i64set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v int64) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s i64set) Sum() interface{} {
	var r int64
	s.Each(func(v int64) {
		r += v
	})
	return r
}

func (s i64set) Product() interface{} {
	r := int64(1)
	s.Each(func(v int64) {
		r *= v
	})
	return r
}