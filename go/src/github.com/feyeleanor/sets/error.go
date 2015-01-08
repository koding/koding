package sets

import (
	"github.com/feyeleanor/slices"
)

type emap	map[error] bool

func (m emap) Len() int {
	return len(m)
}

func (m emap) Member(i interface{}) (r bool) {
	if i, ok := i.(error); ok {
		r = m[i]
	}
	return
}

func (m emap) Include(v interface{}) {
	switch v := v.(type) {
	case []error:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case error:
		m[v] = true
	default:
		panic(v)
	}
}

func (m emap) Each(f interface{}) {
	switch f := f.(type) {
	case func(error):
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

func (m emap) String() (t string) {
	elements := slices.ESlice{}
	m.Each(func(v error) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}


type eset struct {
	emap
}

func ESet(v... error) (r eset) {
	r.emap = make(emap)
	r.Include(v)
	return
}

func (s eset) Empty() Set {
	return ESet()
}

func (s eset) Intersection(o Set) Set {
	r := ESet()
	s.Each(func(v error) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s eset) Union(o Set) Set {
	r := ESet()
	s.Each(func(v error) {
		r.Include(v)
	})
	o.Each(func(v error) {
		r.Include(v)
	})
	return r
}

func (s eset) Difference(o Set) Set {
	r := ESet()
	s.Each(func(v error) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s eset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v error) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}