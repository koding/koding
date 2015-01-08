package sets

import (
	"github.com/feyeleanor/slices"
)

type f64map	map[float64] bool

func (m f64map) Len() int {
	return len(m)
}

func (m f64map) Member(i interface{}) (r bool) {
	if i, ok := i.(float64); ok {
		r = m[i]
	}
	return
}

func (m f64map) Include(v interface{}) {
	switch v := v.(type) {
	case []float64:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case float64:
		m[v] = true
	default:
		panic(v)
	}
}

func (m f64map) Each(f interface{}) {
	switch f := f.(type) {
	case func(float64):
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


type f64set struct {
	f64map
}

func F64Set(v... float64) (r f64set) {
	r.f64map = make(f64map)
	r.Include(v)
	return
}

func (s f64set) Empty() Set {
	return F64Set()
}

func (s f64set) String() (t string) {
	elements := slices.F64Slice{}
	s.Each(func(v float64) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s f64set) Intersection(o Set) Set {
	r := F64Set()
	s.Each(func(v float64) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s f64set) Union(o Set) Set {
	r := F64Set()
	s.Each(func(v float64) {
		r.Include(v)
	})
	o.Each(func(v float64) {
		r.Include(v)
	})
	return r
}

func (s f64set) Difference(o Set) Set {
	r := F64Set()
	s.Each(func(v float64) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s f64set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v float64) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s f64set) Sum() interface{} {
	var r float64
	s.Each(func(v float64) {
		r += v
	})
	return r
}

func (s f64set) Product() interface{} {
	r := float64(1)
	s.Each(func(v float64) {
		r *= v
	})
	return r
}