package structure

import (
	"reflect"
	"testing"
)

func TestMapNonStruct(t *testing.T) {
	foo := []string{"foo"}

	defer func() {
		err := recover()
		if err == nil {
			t.Error("Passing a non struct into Map should panic")
		}
	}()

	// this should panic. We are going to recover and and test it
	_ = Map(foo)
}

func TestMap(t *testing.T) {
	var T = struct {
		A string
		B int
		C bool
	}{
		A: "a-value",
		B: 2,
		C: true,
	}

	a := Map(T)

	if typ := reflect.TypeOf(a).Kind(); typ != reflect.Map {
		t.Errorf("Map should return a map type, got: %v", typ)
	}

	// we have three fields
	if len(a) != 3 {
		t.Errorf("Map should return a map of len 3, got: %d", len(a))
	}

	inMap := func(val interface{}) bool {
		for _, v := range a {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}

		return false
	}

	for _, val := range []interface{}{"a-value", 2, true} {
		if !inMap(val) {
			t.Errorf("Map should have the value %v", val)
		}
	}

}

func TestMap_Tag(t *testing.T) {
	var T = struct {
		A string `structure:"x"`
		B int    `structure:"y"`
		C bool   `structure:"z"`
	}{
		A: "a-value",
		B: 2,
		C: true,
	}

	a := Map(T)

	inMap := func(key interface{}) bool {
		for k := range a {
			if reflect.DeepEqual(k, key) {
				return true
			}
		}
		return false
	}

	for _, key := range []string{"x", "y", "z"} {
		if !inMap(key) {
			t.Errorf("Map should have the key %v", key)
		}
	}

}

func TestMap_Nested(t *testing.T) {
	type A struct {
		Name string
	}
	a := &A{Name: "example"}

	type B struct {
		A *A
	}
	b := &B{A: a}

	m := Map(b)

	if typ := reflect.TypeOf(m).Kind(); typ != reflect.Map {
		t.Errorf("Map should return a map type, got: %v", typ)
	}

	in, ok := m["A"].(map[string]interface{})
	if !ok {
		t.Error("Map nested structs is not available in the map")
	}

	if name := in["Name"].(string); name != "example" {
		t.Error("Map nested struct's name field should give example, got: %s", name)
	}
}

func TestMap_Anonymous(t *testing.T) {
	type A struct {
		Name string
	}
	a := &A{Name: "example"}

	type B struct {
		*A
	}
	b := &B{}
	b.A = a

	m := Map(b)

	if typ := reflect.TypeOf(m).Kind(); typ != reflect.Map {
		t.Errorf("Map should return a map type, got: %v", typ)
	}

	in, ok := m["A"].(map[string]interface{})
	if !ok {
		t.Error("Embedded structs is not available in the map")
	}

	if name := in["Name"].(string); name != "example" {
		t.Error("Embedded A struct's Name field should give example, got: %s", name)
	}
}

func TestStruct(t *testing.T) {
	var T = struct{}{}

	if !IsStruct(T) {
		t.Errorf("T should be a struct, got: %T", T)
	}

	if !IsStruct(&T) {
		t.Errorf("T should be a struct, got: %T", T)
	}

}

func TestValues(t *testing.T) {
	var T = struct {
		A string
		B int
		C bool
	}{
		A: "a-value",
		B: 2,
		C: true,
	}

	s := Values(T)

	if typ := reflect.TypeOf(s).Kind(); typ != reflect.Slice {
		t.Errorf("Values should return a slice type, got: %v", typ)
	}

	inSlice := func(val interface{}) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []interface{}{"a-value", 2, true} {
		if !inSlice(val) {
			t.Errorf("Values should have the value %v", val)
		}
	}
}

func TestValues_Nested(t *testing.T) {
	type A struct {
		Name string
	}
	a := A{Name: "example"}

	type B struct {
		A A
		C int
	}
	b := &B{A: a, C: 123}

	s := Values(b)

	inSlice := func(val interface{}) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []interface{}{"example", 123} {
		if !inSlice(val) {
			t.Errorf("Values should have the value %v", val)
		}
	}
}

func TestValues_Anonymous(t *testing.T) {
	type A struct {
		Name string
	}
	a := A{Name: "example"}

	type B struct {
		A
		C int
	}
	b := &B{C: 123}
	b.A = a

	s := Values(b)

	inSlice := func(val interface{}) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []interface{}{"example", 123} {
		if !inSlice(val) {
			t.Errorf("Values should have the value %v", val)
		}
	}
}

func TestFields(t *testing.T) {
	var T = struct {
		A string
		B int
		C bool
	}{
		A: "a-value",
		B: 2,
		C: true,
	}

	s := Fields(T)

	if len(s) != 3 {
		t.Errorf("Fields should return a slice of len 3, got: %d", len(s))
	}

	inSlice := func(val string) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []string{"A", "B", "C"} {
		if !inSlice(val) {
			t.Errorf("Fields should have the value %v", val)
		}
	}
}

func TestFields_Nested(t *testing.T) {
	type A struct {
		Name string
	}
	a := A{Name: "example"}

	type B struct {
		A A
		C int
	}
	b := &B{A: a, C: 123}

	s := Fields(b)

	inSlice := func(val interface{}) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []interface{}{"Name", "A", "C"} {
		if !inSlice(val) {
			t.Errorf("Fields should have the value %v", val)
		}
	}
}

func TestFields_Anonymous(t *testing.T) {
	type A struct {
		Name string
	}
	a := A{Name: "example"}

	type B struct {
		A
		C int
	}
	b := &B{C: 123}
	b.A = a

	s := Fields(b)

	inSlice := func(val interface{}) bool {
		for _, v := range s {
			if reflect.DeepEqual(v, val) {
				return true
			}
		}
		return false
	}

	for _, val := range []interface{}{"Name", "A", "C"} {
		if !inSlice(val) {
			t.Errorf("Fields should have the value %v", val)
		}
	}
}

func TestIsZero(t *testing.T) {
	var T = struct {
		A string
		B int
		C bool `structure:"-"`
		D []string
	}{
		A: "a-value",
		B: 2,
	}

	ok := IsZero(T)
	if !ok {
		t.Error("IsZero should return true because A and B are initialized.")
	}

	var X = struct {
		A string
		F *bool
	}{
		A: "a-value",
	}

	ok = IsZero(X)
	if !ok {
		t.Error("IsZero should return true because A is initialized")
	}

	var Y = struct {
		A string
		B int
	}{
		A: "a-value",
		B: 123,
	}

	ok = IsZero(Y)
	if ok {
		t.Error("IsZero should return false because A and B is initialized")
	}
}

func TestIsZero_Nested(t *testing.T) {
	type A struct {
		Name string
		D    string
	}
	a := A{Name: "example"}

	type B struct {
		A A
		C int
	}
	b := &B{A: a, C: 123}

	ok := IsZero(b)
	if !ok {
		t.Error("IsZero should return true because D is not initialized")
	}
}

func TestIsZero_Anonymous(t *testing.T) {
	type A struct {
		Name string
		D    string
	}
	a := A{Name: "example"}

	type B struct {
		A
		C int
	}
	b := &B{C: 123}
	b.A = a

	ok := IsZero(b)
	if !ok {
		t.Error("IsZero should return false because D is not initialized")
	}
}

func TestHas(t *testing.T) {
	type A struct {
		Name string
		D    string
	}
	a := A{Name: "example"}

	type B struct {
		A
		C int
	}
	b := &B{C: 123}
	b.A = a

	if !Has(b, "Name") {
		t.Error("Has should return true for Name, but it's false")
	}

	if Has(b, "NotAvailable") {
		t.Error("Has should return false for NotAvailable, but it's true")
	}

	if !Has(b, "C") {
		t.Error("Has should return true for C, but it's false")
	}
}

func TestName(t *testing.T) {
	type Foo struct {
		A string
		B bool
	}
	f := &Foo{}

	n := Name(f)
	if n != "Foo" {
		t.Error("Name should return Foo, got: %s", n)
	}

	unnamed := struct{ Name string }{Name: "Cihangir"}
	m := Name(unnamed)
	if m != "" {
		t.Error("Name should return empty string for unnamed struct, got: %s", n)
	}
}
