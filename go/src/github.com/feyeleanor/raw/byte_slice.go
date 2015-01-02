package raw

//	THIS SHOULD BE IN A SEPARATE PACKAGE WHERE IT CAN BE REUSED MORE EASILY
//	THE PACKAGE SHOULD BE INSTALLABLE VIA GOINSTALL
//	AND NEEDS EXTENSIVE TESTS!!!!

import (
	"reflect"
	"unsafe"
)


var _BYTE_SLICE reflect.Type
var _STRING		reflect.Type

func init() {
	_BYTE_SLICE = reflect.TypeOf([]byte(nil))
	_STRING = reflect.TypeOf("")
}

/*
	A Buffered object can present itself as a byteslice.
	This byteslice can then be manipulated directly to modify the contents of memory.
	Use with extreme caution.
*/
type MemoryBlock interface {
	ByteSlice() []byte
}

func ByteSlice(i interface{}) []byte {
	/*
		A byteslice is by definition its own buffer.
		Any type which implements the Buffer interface will generate its result using that method.
	*/
	switch b := i.(type) {
	case []byte:					return b
	case MemoryBlock:				return b.ByteSlice()
	case nil:						return []byte{}
	}

	/*
		For nil values we return a buffer to a zero-capacity byte slice.
		There are cerain types which cannot be cast as a buffer and instead raise a panic.
		In the rare case of the interface itself containing another interface we recursively query.
		When given a pointer we use its target address and the size of the type it points to construct a SliceHeader.
		For SliceValues we can do a simple conversion of the SliceHeader to a byteslice.
		For StringValues we treat them as a fixed capacity byte slice.
	*/
	var header *reflect.SliceHeader

	switch value := reflect.ValueOf(i); value.Kind() {
	case reflect.Slice:						h, s, _ := SliceHeader(i)
											header = Scale(h, s, 1)

	case reflect.String:					s := value.String()
											stringheader := *(*reflect.StringHeader)(unsafe.Pointer(&s))
											header = &reflect.SliceHeader{ stringheader.Data, stringheader.Len, stringheader.Len }

	case reflect.Interface, reflect.Ptr:	header = valueHeader(value.Elem())

	default:								//	For every other type the value gives us an address for the data
											//	Given this and the size of the underlying allocated memory we can
											//	then create a []byte sliceheader and return a valid slice
											header = valueHeader(value)
	}

	bs := reflect.NewAt(_BYTE_SLICE, unsafe.Pointer(header))
	if !bs.Elem().IsValid() {
		return []byte{}
	}
	return bs.Elem().Interface().([]byte)
}

func valueHeader(v reflect.Value) (h *reflect.SliceHeader) {
	if v.IsValid() {
		size := int(v.Type().Size())
		h = &reflect.SliceHeader{ v.UnsafeAddr(), size, size }
	}
	return
}

func DataAddress(b []byte) (p unsafe.Pointer) {
	defer func() {
		if r := recover(); r != nil {
			p = unsafe.Pointer((*reflect.SliceHeader)(unsafe.Pointer(&b)).Data)
		}
	}()
	return unsafe.Pointer(&(b[0]))
}

func ByteCopy(d interface{}, s interface{}) {
	db := ByteSlice(d)
	sb := ByteSlice(s)
	copy(db, sb)

	dh, element_size, _ := SliceHeader(d)
	dh.Len = len(db) / element_size
	dh.Cap = cap(db) / element_size
}