package raw

import (
	"reflect"
	"unsafe"
)

func sliceHeaderFromValue(v reflect.Value) (s *reflect.SliceHeader) {
	switch v.Kind() {
	case reflect.Slice:						if !v.CanAddr() {
												x := reflect.New(v.Type()).Elem()
												x.Set(v)
												v = x
											}
											s = (*reflect.SliceHeader)(unsafe.Pointer(v.UnsafeAddr()))
	case reflect.Ptr, reflect.Interface:	s = sliceHeaderFromValue(v.Elem())
	}
	return
}

func SliceHeader(i interface{}) (Header *reflect.SliceHeader, ElementSize, ElementAlignment int) {
	value := reflect.ValueOf(i)
	if Header = sliceHeaderFromValue(value); Header != nil {
		ElementType := value.Type().Elem()
		ElementSize = int(ElementType.Size())
		ElementAlignment = int(ElementType.Align())
	} else {
		panic(i)
	}
	return
}

func Scale(oldHeader *reflect.SliceHeader, oldElementSize, newElementSize int) (h *reflect.SliceHeader) {
	if oldHeader != nil {
		s := float64(oldElementSize) / float64(newElementSize)
		h = &reflect.SliceHeader{ Data: oldHeader.Data }
		h.Len = int(float64(oldHeader.Len) * s)
		h.Cap = int(float64(oldHeader.Cap) * s)
	}
	return
}

func Reslice(slice interface{}, sliceType reflect.Type, elementSize int) interface{} {
	b := ByteSlice(slice)
	h := Scale(&reflect.SliceHeader{ uintptr(DataAddress(b)), len(b), cap(b) }, 1, elementSize)
	return reflect.NewAt(sliceType, unsafe.Pointer(h)).Elem().Interface()
}

func PointerSlice(i interface{}) []unsafe.Pointer {
	return Reslice(i, POINTER.slice_type, POINTER.size).([]unsafe.Pointer)
}

func UintptrSlice(i interface{}) []uintptr {
	return Reslice(i, UINTPTR.slice_type, UINTPTR.size).([]uintptr)
}

func InterfaceSlice(i interface{}) []interface{} {
	return Reslice(i, INTERFACE.slice_type, INTERFACE.size).([]interface{})
}

func BoolSlice(i interface{}) []bool {
	return Reslice(i, BOOLEAN.slice_type, BOOLEAN.size).([]bool)
}

func IntSlice(i interface{}) []int {
	if i, ok := i.([]uint); ok {
		return *(*[]int)(unsafe.Pointer(&i))
	}
	return Reslice(i, INT.slice_type, INT.size).([]int)
}

func Int8Slice(i interface{}) []int8 {
	if i, ok := i.([]uint8); ok {
		return *(*[]int8)(unsafe.Pointer(&i))
	}
	return Reslice(i, INT8.slice_type, INT8.size).([]int8)
}

func Int16Slice(i interface{}) []int16 {
	if i, ok := i.([]uint16); ok {
		return *(*[]int16)(unsafe.Pointer(&i))
	}
	return Reslice(i, INT16.slice_type, INT16.size).([]int16)
}

func Int32Slice(i interface{}) []int32 {
	switch i := i.(type) {
	case []uint32:
		return *(*[]int32)(unsafe.Pointer(&i))
	case []float32:
		return *(*[]int32)(unsafe.Pointer(&i))
	}
	return Reslice(i, INT32.slice_type, INT32.size).([]int32)
}

func Int64Slice(i interface{}) []int64 {
	switch i := i.(type) {
	case []uint64:
		return *(*[]int64)(unsafe.Pointer(&i))
	case []float64:
		return *(*[]int64)(unsafe.Pointer(&i))
	}
	return Reslice(i, INT64.slice_type, INT64.size).([]int64)
}

func UintSlice(i interface{}) []uint {
	if i, ok := i.([]int); ok {
		return *(*[]uint)(unsafe.Pointer(&i))
	}
	return Reslice(i, UINT.slice_type, UINT.size).([]uint)
}

func Uint8Slice(i interface{}) []uint8 {
	if i, ok := i.([]int8); ok {
		return *(*[]uint8)(unsafe.Pointer(&i))
	}
	return Reslice(i, UINT8.slice_type, UINT8.size).([]uint8)
}

func Uint16Slice(i interface{}) []uint16 {
	if i, ok := i.([]int16); ok {
		return *(*[]uint16)(unsafe.Pointer(&i))
	}
	return Reslice(i, UINT16.slice_type, UINT16.size).([]uint16)
}

func Uint32Slice(i interface{}) []uint32 {
	switch i := i.(type) {
	case []int32:
		return *(*[]uint32)(unsafe.Pointer(&i))
	case []float32:
		return *(*[]uint32)(unsafe.Pointer(&i))
	}
	return Reslice(i, UINT32.slice_type, UINT32.size).([]uint32)
}

func Uint64Slice(i interface{}) []uint64 {
	switch i := i.(type) {
	case []int64:
		return *(*[]uint64)(unsafe.Pointer(&i))
	case []float64:
		return *(*[]uint64)(unsafe.Pointer(&i))
	}
	return Reslice(i, UINT64.slice_type, UINT64.size).([]uint64)
}

func Float32Slice(i interface{}) []float32 {
	switch i := i.(type) {
	case []int32:
		return *(*[]float32)(unsafe.Pointer(&i))
	case []uint32:
		return *(*[]float32)(unsafe.Pointer(&i))
	}
	return Reslice(i, FLOAT32.slice_type, FLOAT32.size).([]float32)
}

func Float64Slice(i interface{}) []float64 {
	switch i := i.(type) {
	case []int64:
		return *(*[]float64)(unsafe.Pointer(&i))
	case []uint64:
		return *(*[]float64)(unsafe.Pointer(&i))
	case []complex64:
		return *(*[]float64)(unsafe.Pointer(&i))
	}
	return Reslice(i, FLOAT64.slice_type, FLOAT64.size).([]float64)
}

func Complex64Slice(i interface{}) []complex64 {
	switch i := i.(type) {
	case []int64:
		return *(*[]complex64)(unsafe.Pointer(&i))
	case []uint64:
		return *(*[]complex64)(unsafe.Pointer(&i))
	case []float64:
		return *(*[]complex64)(unsafe.Pointer(&i))
	}
	return Reslice(i, COMPLEX64.slice_type, COMPLEX64.size).([]complex64)
}

func Complex128Slice(i interface{}) []complex128 {
	return Reslice(i, COMPLEX128.slice_type, COMPLEX128.size).([]complex128)
}