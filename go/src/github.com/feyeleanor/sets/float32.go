package sets

import (
	"github.com/feyeleanor/slices"
)

type f32map	map[float32] bool

func (m f32map) Len() int {
	return len(m)
}

func (m f32map) Member(i interface{}) (r bool) {
	if i, ok := i.(float32); ok {
		r = m[i]
	}
	return
}

func (m f32map) Include(v interface{}) {
	switch v := v.(type) {
	case []float32:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case float32:
		m[v] = true
	default:
		panic(v)
	}
}

func (m f32map) Each(f interface{}) {
	switch f := f.(type) {
	case func(float32):
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


type f32set struct {
	f32map
}

func F32Set(v... float32) (r f32set) {
	r.f32map = make(f32map)
	r.Include(v)
	return
}

func (s f32set) Empty() Set {
	return F32Set()
}

func (s f32set) String() (t string) {
	elements := slices.F32Slice{}
	s.Each(func(v float32) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s f32set) Intersection(o Set) Set {
	r := F32Set()
	s.Each(func(v float32) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s f32set) Union(o Set) Set {
	r := F32Set()
	s.Each(func(v float32) {
		r.Include(v)
	})
	o.Each(func(v float32) {
		r.Include(v)
	})
	return r
}

func (s f32set) Difference(o Set) Set {
	r := F32Set()
	s.Each(func(v float32) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s f32set) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v float32) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s f32set) Sum() interface{} {
	var r float32
	s.Each(func(v float32) {
		r += v
	})
	return r
}

func (s f32set) Product() interface{} {
	r := float32(1)
	s.Each(func(v float32) {
		r *= v
	})
	return r
}