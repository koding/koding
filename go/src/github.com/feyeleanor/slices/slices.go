package slices

import (
	"math/rand"
	"reflect"
	"sort"
)

const(
	IS_LESS_THAN	= iota - 1
	IS_SAME_AS
	IS_GREATER_THAN
)

type Nested interface {
	Depth() int
}

type Flattenable interface {
	Flatten()
}

type Equatable interface {
	Equal(interface{}) bool
}

type Typed interface {
	Type() reflect.Type
}

type Insertable interface {
	Len() int
	Insert(int, interface{})
}

type Container interface {
	Len() int
	At(int) interface{}
	Set(int, interface{})
}

type Deck interface {
	Len() int
	Swap(i, j int)
}

type Wipeable interface {
	Len() int
	BlockClear(int, int)
}

var(
	NESTED = reflect.TypeOf((*Nested)(nil)).Elem()
	FLATTENABLE = reflect.TypeOf((*Flattenable)(nil)).Elem()
	EQUATABLE = reflect.TypeOf((*Equatable)(nil)).Elem()
	TYPED = reflect.TypeOf((*Typed)(nil)).Elem()
	INSERTABLE = reflect.TypeOf((*Insertable)(nil)).Elem()
	CONTAINER = reflect.TypeOf((*Container)(nil)).Elem()
)

func CanFlatten(s interface{}) (ok bool) {
	switch s := s.(type) {
	case reflect.Value:
		ok = s.Kind() == reflect.Slice || s.Type().Implements(FLATTENABLE)
	default:
		v := reflect.ValueOf(s)
		ok = v.Kind() == reflect.Slice || v.Type().Implements(FLATTENABLE)
	}
	return
}

func Prepend(i Insertable, value interface{}) {
	i.Insert(0, value)
}

func Append(i Insertable, value interface{}) {
	i.Insert(i.Len(), value)
}

func Shuffle(d Deck) {
	for i, v := range rand.Perm(d.Len()) {
		if v > i {
			d.Swap(i, v)
		}
	}
}

func ClearAll(i interface{}) (r bool) {
	if i, ok := i.(Wipeable); ok {
		i.BlockClear(0, i.Len())
		r = true
	}
	return
}

func Equal(e, o interface{}) (r bool) {
	if e, ok := e.(Equatable); ok {
		r = e.Equal(o)
	} else if o, ok := o.(Equatable); ok {
		r = o.Equal(e)
	}
	return
}

func Sort(i interface{}) (r bool) {
	if i, ok := i.(sort.Interface); ok {
		sort.Sort(i)
		r = true
	}
	return
}