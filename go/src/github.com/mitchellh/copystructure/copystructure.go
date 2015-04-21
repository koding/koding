package copystructure

import (
	"reflect"

	"github.com/mitchellh/reflectwalk"
)

// Copy returns a deep copy of v.
func Copy(v interface{}) (interface{}, error) {
	w := new(walker)
	err := reflectwalk.Walk(v, w)
	if err != nil {
		return nil, err
	}

	return w.Result, nil
}

type walker struct {
	Result interface{}

	vals []reflect.Value
	cs   []reflect.Value
	ps   []bool
}

func (w *walker) Enter(l reflectwalk.Location) error {
	return nil
}

func (w *walker) Exit(l reflectwalk.Location) error {
	switch l {
	case reflectwalk.Map:
		fallthrough
	case reflectwalk.Slice:
		// Pop map off our container
		w.cs = w.cs[:len(w.cs)-1]
	case reflectwalk.MapValue:
		// Pop off the key and value
		mv := w.valPop()
		mk := w.valPop()
		m := w.cs[len(w.cs)-1]
		m.SetMapIndex(mk, mv)
	case reflectwalk.SliceElem:
		// Pop off the value and the index and set it on the slice
		v := w.valPop()
		i := w.valPop().Interface().(int)
		s := w.cs[len(w.cs)-1]
		s.Index(i).Set(v)
	case reflectwalk.Struct:
		w.replacePointerMaybe()

		// Remove the struct from the container stack
		w.cs = w.cs[:len(w.cs)-1]
	case reflectwalk.StructField:
		// Pop off the value and the field
		v := w.valPop()
		f := w.valPop().Interface().(reflect.StructField)
		s := w.cs[len(w.cs)-1]
		sf := reflect.Indirect(s).FieldByName(f.Name)
		sf.Set(v)
	case reflectwalk.WalkLoc:
		// Clear out the slices for GC
		w.cs = nil
		w.vals = nil
	}

	return nil
}

func (w *walker) Map(m reflect.Value) error {
	t := m.Type()
	newMap := reflect.MakeMap(reflect.MapOf(t.Key(), t.Elem()))
	w.cs = append(w.cs, newMap)
	w.valPush(newMap)
	return nil
}

func (w *walker) MapElem(m, k, v reflect.Value) error {
	return nil
}

func (w *walker) PointerEnter(v bool) error {
	w.ps = append(w.ps, v)
	return nil
}

func (w *walker) PointerExit(bool) error {
	w.ps = w.ps[:len(w.ps)-1]
	return nil
}

func (w *walker) Primitive(v reflect.Value) error {
	newV := reflect.New(v.Type())
	reflect.Indirect(newV).Set(v)
	w.valPush(newV)
	w.replacePointerMaybe()
	return nil
}

func (w *walker) Slice(s reflect.Value) error {
	newS := reflect.MakeSlice(s.Type(), s.Len(), s.Cap())
	w.cs = append(w.cs, newS)
	w.valPush(newS)
	return nil
}

func (w *walker) SliceElem(i int, elem reflect.Value) error {
	// We don't write the slice here because elem might still be
	// arbitrarily complex. Just record the index and continue on.
	w.valPush(reflect.ValueOf(i))

	return nil
}

func (w *walker) Struct(s reflect.Value) error {
	// Make a copy of this struct and remove the pointer since we're
	// not usually dealing with the pointer at this stage.
	v := reflect.New(s.Type())
	w.valPush(v)
	w.cs = append(w.cs, v)
	return nil
}

func (w *walker) StructField(f reflect.StructField, v reflect.Value) error {
	// Push the field onto the stack, we'll handle it when we exit
	// the struct field in Exit...
	w.valPush(reflect.ValueOf(f))
	return nil
}

func (w *walker) pointerPeek() bool {
	return w.ps[len(w.ps)-1]
}

func (w *walker) valPop() reflect.Value {
	result := w.vals[len(w.vals)-1]
	w.vals = w.vals[:len(w.vals)-1]

	// If we're out of values, that means we popped everything off. In
	// this case, we reset the result so the next pushed value becomes
	// the result.
	if len(w.vals) == 0 {
		w.Result = nil
	}

	return result
}

func (w *walker) valPush(v reflect.Value) {
	w.vals = append(w.vals, v)

	// If we haven't set the result yet, then this is the result since
	// it is the first (outermost) value we're seeing.
	if w.Result == nil {
		w.Result = v.Interface()
	}
}

func (w *walker) replacePointerMaybe() {
	// Determine the last pointer value. If it is NOT a pointer, then
	// we need to push that onto the stack.
	if !w.pointerPeek() {
		w.valPush(reflect.Indirect(w.valPop()))
	}
}
