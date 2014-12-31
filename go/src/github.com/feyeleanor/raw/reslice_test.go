package raw

import (
	"fmt"
	"reflect"
	"testing"
	"unsafe"
)


type HeaderMismatch struct{
	message			string
	x, y, z			interface{}
}

func (h HeaderMismatch) Error() string {
	return fmt.Sprintf(h.message, h.x, h.y, h.z)
}

func MatchHeaders(b BasicType, slice interface{}, header reflect.SliceHeader) (e error) {
	h, s, al := SliceHeader(slice)
	switch {
	case s != b.size:			e = HeaderMismatch{ "%v: slice element size should be %v not %v", b.name, b.size, s }
	case al != b.alignment:		e = HeaderMismatch{ "%v: slice element alignment should be %v not %v", b.name, b.alignment, al }
	case h.Data != header.Data:	e = HeaderMismatch{ "%v: slice headers should point to the same memory: %v - %v", b.name, h.Data, header.Data }
	case h.Len != header.Len:	e = HeaderMismatch{ "%v: slice header lengths should be the same: %v - %v", b.name, h.Len, header.Len }
	case h.Cap != header.Cap:	e = HeaderMismatch{ "%v: slice header capacities should be the same: %v - %v", b.name, h.Cap, header.Cap }
	}
	return
}

func TestSliceHeaderByte(t *testing.T) {
	slice := []byte{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(BYTE, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderPointer(t *testing.T) {
	a, b, c, d, e, f := 0, 1, 2, 3, 4, 5
	slice := []unsafe.Pointer{ unsafe.Pointer(&a), unsafe.Pointer(&b), unsafe.Pointer(&c), unsafe.Pointer(&d), unsafe.Pointer(&e), unsafe.Pointer(&f) }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(POINTER, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderUintptr(t *testing.T) {
	slice := []uintptr{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(UINTPTR, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderInterface(t *testing.T) {
	t.Log("Awaiting bug fix for incorrect reporting of interface{} value size with unsafe.Sizeof()")
/*
	slice := []interface{}{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(INTERFACE, slice, header); m != nil {
		t.Fatal(m)
	}
*/
}

func TestSliceHeaderBool(t *testing.T) {
	slice := []bool{ true, false, true, false, false, true }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(BOOLEAN, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderUint(t *testing.T) {
	slice := []uint{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(UINT, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderUint8(t *testing.T) {
	slice := []uint8{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(UINT8, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderUint16(t *testing.T) {
	slice := []uint16{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(UINT16, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderUint32(t *testing.T) {
	slice := []uint32{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(UINT32, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderInt(t *testing.T) {
	slice := []int{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(INT, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderInt8(t *testing.T) {
	slice := []int8{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(INT8, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderInt16(t *testing.T) {
	slice := []int16{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(INT16, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderInt32(t *testing.T) {
	slice := []int32{ 0, 1, 2, 3, 4, 5 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(INT32, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderFloat32(t *testing.T) {
	slice := []float32{ 0.0, 1.0, 2.0, 3.0, 4.0, 5.0 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(FLOAT32, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderFloat64(t *testing.T) {
	slice := []float64{ 0.0, 1.0, 2.0, 3.0, 4.0, 5.0 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(FLOAT64, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderComplex64(t *testing.T) {
	slice := []complex64{ 0, 0, 0, 0, 0, 0 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(COMPLEX64, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestSliceHeaderComplex128(t *testing.T) {
	slice := []complex128{ 0, 0, 0, 0, 0, 0 }
	header := *(*reflect.SliceHeader)(unsafe.Pointer(&slice))
	if m := MatchHeaders(COMPLEX128, slice, header); m != nil {
		t.Fatal(m)
	}
}

func TestScale(t *testing.T) {
	var h 	*reflect.SliceHeader

	if Scale(h, 0, 0) != nil {
		t.Fatal("Scaling a nil *SliceHeader should return a nil *SliceHeader")
	}

	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
	h, _, _ = SliceHeader(b)
	hs := Scale(h, 1, 2)
	switch {
	case hs.Len != h.Len / 2:	t.Fatalf("new slice length should be %v not %v", h.Len / 2, hs.Len)
	case hs.Cap != h.Cap / 2:	t.Fatalf("new slice capacity should be %v not %v", h.Cap / 2, hs.Cap)
	}

	i32 := []int32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
	h, _, _ = SliceHeader(i32)
	hs = Scale(h, INT32.size, BYTE.size)
	switch {
	case hs.Len != h.Len * INT32.size / BYTE.size:
		t.Fatalf("new slice length should be %v not %v", h.Len * INT32.size / BYTE.size, hs.Len)
	case hs.Cap != h.Cap * INT32.size / BYTE.size:
		t.Fatalf("new slice capacity should be %v not %v", h.Cap * INT32.size / BYTE.size, hs.Cap)
	}
}

func TestResliceNil(t *testing.T) {
	var h 	*reflect.SliceHeader

	hs := &reflect.SliceHeader{}
	h, _, _ = SliceHeader(Reslice(h, INT32.slice_type, INT32.size))
	switch {
	case h.Len != hs.Len:	t.Fatalf("SliceHeader reslice length should be %v not %v", h.Len, hs.Len)
	case h.Cap != hs.Cap:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", h.Cap, hs.Cap)
	}
}

func TestReslice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	h, _, _ := SliceHeader(b)
	switch {
	case h.Len != len(b):	t.Fatalf("1. SliceHeader reslice length should be %v not %v", h.Len, len(b))
	case h.Cap != cap(b):	t.Fatalf("1. SliceHeader reslice capacity should be %v not %v", h.Cap, cap(b))
	}

	s := Reslice(b, INT32.slice_type, INT32.size).([]int32)
	switch {
	case len(s) != len(b) / 4:	t.Fatalf("2. SliceHeader reslice length should be %v not %v", len(b) / 4, len(s))
	case cap(s) != cap(b) / 4:	t.Fatalf("2. SliceHeader reslice capacity should be %v not %v", cap(b) / 4, cap(s))
	}
}

func TestPointerSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := PointerSlice(b)
	switch {
	case len(p) != len(b) / POINTER.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / POINTER.size)
	case len(p) != cap(b) / POINTER.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / POINTER.size)
	}
}

func TestUintptrSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := UintptrSlice(b)
	switch {
	case len(p) != len(b) / UINTPTR.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINTPTR.size)
	case len(p) != cap(b) / UINTPTR.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINTPTR.size)
	}
}

func TestInterfaceSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := InterfaceSlice(b)
	switch {
	case len(p) != len(b) / INTERFACE.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INTERFACE.size)
	case len(p) != cap(b) / INTERFACE.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INTERFACE.size)
	}
}

func TestBoolSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := BoolSlice(b)
	switch {
	case len(p) != len(b) / BOOLEAN.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / BOOLEAN.size)
	case len(p) != cap(b) / BOOLEAN.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / BOOLEAN.size)
	}
}

func TestIntSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := IntSlice(b)
	switch {
	case len(p) != len(b) / INT.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INT.size)
	case len(p) != cap(b) / INT.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INT.size)
	}
}

func TestInt8Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Int8Slice(b)
	switch {
	case len(p) != len(b) / INT8.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INT8.size)
	case len(p) != cap(b) / INT8.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INT8.size)
	}
}

func TestInt16Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Int16Slice(b)
	switch {
	case len(p) != len(b) / INT16.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INT16.size)
	case len(p) != cap(b) / INT16.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INT16.size)
	}
}

func TestInt32Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Int32Slice(b)
	switch {
	case len(p) != len(b) / INT32.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INT32.size)
	case len(p) != cap(b) / INT32.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INT32.size)
	}
}

func TestInt64Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Int64Slice(b)
	switch {
	case len(p) != len(b) / INT64.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / INT64.size)
	case len(p) != cap(b) / INT64.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / INT64.size)
	}
}

func TestUintSlice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := UintSlice(b)
	switch {
	case len(p) != len(b) / UINT.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINT.size)
	case len(p) != cap(b) / UINT.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINT.size)
	}
}

func TestUint8Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Uint8Slice(b)
	switch {
	case len(p) != len(b) / UINT8.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINT8.size)
	case len(p) != cap(b) / UINT8.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINT8.size)
	}
}

func TestUint16Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Uint16Slice(b)
	switch {
	case len(p) != len(b) / UINT16.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINT16.size)
	case len(p) != cap(b) / UINT16.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINT16.size)
	}
}

func TestUint32Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Uint32Slice(b)
	switch {
	case len(p) != len(b) / UINT32.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINT32.size)
	case len(p) != cap(b) / UINT32.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINT32.size)
	}
}

func TestUint64Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Uint64Slice(b)
	switch {
	case len(p) != len(b) / UINT64.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / UINT64.size)
	case len(p) != cap(b) / UINT64.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / UINT64.size)
	}
}

func TestFloat32Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Float32Slice(b)
	switch {
	case len(p) != len(b) / FLOAT32.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / FLOAT32.size)
	case len(p) != cap(b) / FLOAT32.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / FLOAT32.size)
	}
}

func TestFloat64Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Float64Slice(b)
	switch {
	case len(p) != len(b) / FLOAT64.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / FLOAT64.size)
	case len(p) != cap(b) / FLOAT64.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / FLOAT64.size)
	}
}

func TestComplex64Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Complex64Slice(b)
	switch {
	case len(p) != len(b) / COMPLEX64.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / COMPLEX64.size)
	case len(p) != cap(b) / COMPLEX64.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / COMPLEX64.size)
	}
}

func TestComplex128Slice(t *testing.T) {
	b := []byte{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	p := Complex128Slice(b)
	switch {
	case len(p) != len(b) / COMPLEX128.size:	t.Fatalf("SliceHeader reslice length should be %v not %v", len(p), len(b) / COMPLEX128.size)
	case len(p) != cap(b) / COMPLEX128.size:	t.Fatalf("SliceHeader reslice capacity should be %v not %v", cap(p), cap(b) / COMPLEX128.size)
	}
}