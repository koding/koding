package sets

import (
	"github.com/feyeleanor/slices"
)

type smap	map[string] bool

func (m smap) Len() int {
	return len(m)
}

func (m smap) Member(i interface{}) (r bool) {
	if i, ok := i.(string); ok {
		r = m[i]
	}
	return
}

func (m smap) Include(v interface{}) {
	switch v := v.(type) {
	case []string:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case string:
		m[v] = true
	default:
		panic(v)
	}
}

func (m smap) Each(f interface{}) {
	switch f := f.(type) {
	case func(string):
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


type sset struct {
	smap
}

func SSet(v... string) (r sset) {
	r.smap = make(smap)
	r.Include(v)
	return
}

func (s sset) Empty() Set {
	return SSet()
}

func (s sset) String() (t string) {
	elements := slices.SSlice{}
	s.Each(func(v string) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s sset) Intersection(o Set) Set {
	r := SSet()
	s.Each(func(v string) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s sset) Union(o Set) Set {
	r := SSet()
	s.Each(func(v string) {
		r.Include(v)
	})
	o.Each(func(v string) {
		r.Include(v)
	})
	return r
}

func (s sset) Difference(o Set) Set {
	r := SSet()
	s.Each(func(v string) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s sset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v string) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}