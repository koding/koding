package sets

import (
	"github.com/feyeleanor/slices"
)

type umap	map[uint] bool

func (m umap) Len() int {
	return len(m)
}

func (m umap) Member(i interface{}) (r bool) {
	if i, ok := i.(uint); ok {
		r = m[i]
	}
	return
}

func (m umap) Include(v interface{}) {
	switch v := v.(type) {
	case []uint:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uint:
		m[v] = true
	default:
		panic(v)
	}
}

func (m umap) Each(f interface{}) {
	switch f := f.(type) {
	case func(uint):
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


type uset struct {
	umap
}

func USet(v... uint) (r uset) {
	r.umap = make(umap)
	r.Include(v)
	return
}

func (s uset) Empty() Set {
	return USet()
}

func (s uset) String() (t string) {
	elements := slices.USlice{}
	s.Each(func(v uint) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s uset) Intersection(o Set) Set {
	r := USet()
	s.Each(func(v uint) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s uset) Union(o Set) Set {
	r := USet()
	s.Each(func(v uint) {
		r.Include(v)
	})
	o.Each(func(v uint) {
		r.Include(v)
	})
	return r
}

func (s uset) Difference(o Set) Set {
	r := USet()
	s.Each(func(v uint) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s uset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uint) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s uset) Sum() interface{} {
	var r uint
	s.Each(func(v uint) {
		r += v
	})
	return r
}

func (s uset) Product() interface{} {
	r := uint(1)
	s.Each(func(v uint) {
		r *= v
	})
	return r
}