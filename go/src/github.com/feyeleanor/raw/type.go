package raw

import (
	"fmt"
	"reflect"
	"unsafe"
)

func ConcreteValue(value interface{}) (r reflect.Value) {
	for r = reflect.ValueOf(value); r.Kind() == reflect.Ptr; r = reflect.Indirect(r) {}
	return
}

func MakeAddressable(value reflect.Value) reflect.Value {
	if !value.CanAddr() {
		ptr := reflect.New(value.Type()).Elem()
		ptr.Set(value)
		value = ptr
	}
	return value
}

func Assign(location, value reflect.Value) {
	location = MakeAddressable(location)
	location.Set(value)
}

type Typed interface {
	Type() reflect.Type
}

func Type(v interface{}) (r reflect.Type) {
	switch v := v.(type) {
	case Typed:				r = v.Type()
	default:				r = reflect.TypeOf(v)
	}
	return
}

func Compatible(l, r interface{}) (b bool) {
	CatchAll(func() {
		l, r := Type(l), Type(r)
		switch {
		case l.Kind() == reflect.Chan && r.Kind() == reflect.Chan:		b = l.Elem() == r.Elem() && l.ChanDir() == r.ChanDir()
		case l.Kind() == reflect.Chan, r.Kind() == reflect.Chan:		b = l.Elem() == r.Elem()
		case l.Kind() == reflect.Map && r.Kind() == reflect.Map:		b = l.Elem() == r.Elem() && l.Key() == r.Key()
		case l.Kind() == reflect.Map:									b = l.Key() == Type(INT) && l.Elem() == r.Elem()
		case r.Kind() == reflect.Map:									b = r.Key() == Type(INT) && l.Elem() == r.Elem()
		default:														b = l.Elem() == r.Elem()
		}
	})
	return
}

func RegisterType(name string, v, s interface{}) (r BasicType) {
	r.name = name
	r._type = reflect.TypeOf(v)
	r.size = int(r._type.Size())
	r.alignment = int(r._type.Align())
	r.slice_type = reflect.TypeOf(s)
	return
}

type BasicType struct {
	_type			reflect.Type
	name			string
	size			int
	alignment		int
	slice_type		reflect.Type
}

func (b BasicType) Type() reflect.Type {
	return b._type
}

func (b BasicType) String() string {
	return fmt.Sprintf("%v: %v bytes aligned at %v byte", b.name, b.size, b.alignment)
}

var _a interface{} = 0

var POINTER		= RegisterType("unsafe.Pointer", unsafe.Pointer(&_a), []unsafe.Pointer{})
var UINTPTR		= RegisterType("uintptr", uintptr(0), []uintptr{})
var INTERFACE	= RegisterType("interface{}", _a, []interface{}{})
var BOOLEAN		= RegisterType("bool", true, []bool{})
var BYTE		= RegisterType("byte", byte(0), []byte{})
var INT			= RegisterType("int", int(0), []int{})
var INT8		= RegisterType("int8", int8(0), []int8{})
var INT16		= RegisterType("int16", int16(0), []int16{})
var INT32		= RegisterType("int32", int32(0), []int32{})
var INT64		= RegisterType("int64", int64(0), []int64{})
var UINT		= RegisterType("uint", uint(0), []uint{})
var UINT8		= RegisterType("uint8", uint8(0), []uint8{})
var UINT16		= RegisterType("uint16", uint16(0), []uint16{})
var UINT32		= RegisterType("uint32", uint32(0), []uint32{})
var UINT64		= RegisterType("uint64", uint64(0), []uint64{})
var FLOAT32		= RegisterType("float32", float32(0.0), []float32{})
var FLOAT64		= RegisterType("float64", float64(0.0), []float64{})
var COMPLEX64	= RegisterType("complex64", complex64(0), []complex64{})
var COMPLEX128	= RegisterType("complex128", complex128(0), []complex128{})