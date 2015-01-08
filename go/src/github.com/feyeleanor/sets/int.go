package sets

import (
	"github.com/feyeleanor/slices"
)

type imap	map[int] bool

func (m imap) Len() int {
	return len(m)
}

func (m imap) Member(i interface{}) (r bool) {
	if i, ok := i.(int); ok {
		r = m[i]
	}
	return
}

func (m imap) Include(v interface{}) {
	switch v := v.(type) {
	case []int:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case int:
		m[v] = true
	default:
		panic(v)
	}
}

func (m imap) Each(f interface{}) {
	switch f := f.(type) {
	case func(int):
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


type iset struct {
	imap
}

func ISet(v... int) (r iset) {
	r.imap = make(imap)
	r.Include(v)
	return
}

func (s iset) Empty() Set {
	return ISet()
}

func (s iset) String() (t string) {
	elements := slices.ISlice{}
	s.Each(func(v int) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s iset) Intersection(o Set) Set {
	r := ISet()
	s.Each(func(v int) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s iset) Union(o Set) Set {
	r := ISet()
	s.Each(func(v int) {
		r.Include(v)
	})
	o.Each(func(v int) {
		r.Include(v)
	})
	return r
}

func (s iset) Difference(o Set) Set {
	r := ISet()
	s.Each(func(v int) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s iset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v int) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s iset) Sum() interface{} {
	var r int
	s.Each(func(v int) {
		r += v
	})
	return r
}

func (s iset) Product() interface{} {
	r := int(1)
	s.Each(func(v int) {
		r *= v
	})
	return r
}