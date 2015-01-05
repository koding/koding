package sets

type Set interface {
	Len() int
	Empty() Set
	Include(interface{})
	Member(interface{}) bool
	Each(interface{})
}

type NumericSet interface {
	Set
	Sum() interface{}
	Product() interface{}
}

type Equatable interface {
	Equal(interface{}) bool
}

func SubsetOf(x, y Set) (r bool) {
	defer func() {
		recover()
	}()
	r = true
	x.Each(func(v interface{}) {
		if !y.Member(v) {
			r = false
			panic(r)
		}
	})
	return
}

func Intersection(l, r Set) Set {
	n := l.Empty()
	l.Each(func(v interface{}) {
		if r.Member(v) {
			n.Include(v)
		}
	})
	return n
}

func Union(l, r Set) Set {
	n := l.Empty()
	l.Each(func(v interface{}) {
		n.Include(v)
	})
	r.Each(func(v interface{}) {
		n.Include(v)
	})
	return n
}

func Difference(l, r Set) Set {
	n := l.Empty()
	l.Each(func(v interface{}) {
		if !r.Member(v) {
			n.Include(v)
		}
	})
	return n
}