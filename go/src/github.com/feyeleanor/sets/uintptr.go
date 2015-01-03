package sets

import (
	"github.com/feyeleanor/slices"
)

type amap	map[uintptr] bool

func (m amap) Len() int {
	return len(m)
}

func (m amap) Member(i interface{}) (r bool) {
	if i, ok := i.(uintptr); ok {
		r = m[i]
	}
	return
}

func (m amap) Include(v interface{}) {
	switch v := v.(type) {
	case []uintptr:
		for i := len(v) - 1; i > -1; i-- {
			m[v[i]] = true
		}
	case uintptr:
		m[v] = true
	default:
		panic(v)
	}
}

func (m amap) Each(f interface{}) {
	switch f := f.(type) {
	case func(uintptr):
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


type aset struct {
	amap
}

func ASet(v... uintptr) (r aset) {
	r.amap = make(amap)
	r.Include(v)
	return
}

func (s aset) Empty() Set {
	return ASet()
}

func (s aset) String() (t string) {
	elements := slices.ASlice{}
	s.Each(func(v uintptr) {
		elements = append(elements, v)
	})
	slices.Sort(elements)
	return elements.String()
}

func (s aset) Intersection(o Set) Set {
	r := ASet()
	s.Each(func(v uintptr) {
		if o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s aset) Union(o Set) Set {
	r := ASet()
	s.Each(func(v uintptr) {
		r.Include(v)
	})
	o.Each(func(v uintptr) {
		r.Include(v)
	})
	return r
}

func (s aset) Difference(o Set) Set {
	r := ASet()
	s.Each(func(v uintptr) {
		if !o.Member(v) {
			r.Include(v)
		}
	})
	return r
}

func (s aset) Equal(o interface{}) (r bool) {
	if o, ok := o.(Set); ok {
		if r = s.Len() == o.Len(); r {
			s.Each(func(v uintptr) {
				if !o.Member(v) {
					r = false
				}
			})
		}
	}
	return
}

func (s aset) Sum() interface{} {
	var r uintptr
	s.Each(func(v uintptr) {
		r += v
	})
	return r
}

func (s aset) Product() interface{} {
	r := uintptr(1)
	s.Each(func(v uintptr) {
		r *= v
	})
	return r
}