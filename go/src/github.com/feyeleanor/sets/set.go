package sets

import (
	"github.com/feyeleanor/slices"
)

type vmap map[interface{}] bool

func (m vmap) Len() int {
	return len(m)
}

func (m vmap) Member(i interface{}) bool {
	return m[i]
}

func (m vmap) Include(v interface{}) {
	if x, ok := v.([]interface{}); ok {
		for i := len(x) - 1; i > -1; i-- {
			m[x[i]] = true
		}
	} else {
		m[v] = true
	}
}

func (m vmap) Each(f interface{}) {
	switch f := f.(type) {
	case func(interface{}):
		for k, v := range m {
			if v {
				f(k)
			}
		}
	}
}

func (m vmap) String() (t string) {
	elements := slices.Slice{}
	m.Each(func(v interface{}) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}


type vset struct {
	vmap
}

func VSet(v... interface{}) (r vset) {
	r.vmap = make(vmap)
	r.Include(v)
	return
}

func (s vset) Empty() Set {
	return VSet()
}

func (s vset) Intersection(o Set) Set {
	r := VSet()
	s.Each(func(v interface{}) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s vset) Union(o Set) Set {
	r := VSet()
	s.Each(func(v interface{}) {
		r.Include(v)
	})
	o.Each(func(v interface{}) {
		r.Include(v)
	})
	return r
}

func (s vset) Difference(o Set) Set {
	r := VSet()
	s.Each(func(v interface{}) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s vset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v interface{}) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}