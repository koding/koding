package provider

import (
	"encoding/json"
	"strconv"
)

// Slice is a workaround for hcl.DecodeObject,
// which always appends to existing slices,
// thus making the output of DecodeObject
// non-idempotent, as it always doubles
// any slices values.
//
// Wrapping a slice value with ToSlice
// prevents from doubling the items
// on hcl.DecodeObject.
type Slice map[string]interface{}

var (
	_ json.Marshaler   = new(Slice)
	_ json.Unmarshaler = new(Slice)
)

func (s *Slice) init(v []interface{}) {
	*s = make(Slice, len(v))

	for i := range v {
		(*s)[strconv.Itoa(i)] = v[i]
	}
}

func (s Slice) slice() []interface{} {
	max := 0
	slice := make([]interface{}, len(s))

	for k, v := range s {
		i, err := strconv.Atoi(k)
		if err != nil {
			// HCL's decoder errornously merges object's keys
			// into the slice. In order to make it working,
			// we just ignore them.
			continue
		}

		slice[i] = v

		if i > max {
			max = i
		}
	}

	return slice[:max+1]
}

// MarshalJSON implements the json.Marshaler interface.
func (s Slice) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.slice())
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (s *Slice) UnmarshalJSON(p []byte) error {
	var slice []interface{}

	if err := json.Unmarshal(p, &slice); err != nil {
		return err
	}

	s.init(slice)

	return nil
}

// ToSlice creates a Slice value out of slice argument.
func ToSlice(slice []interface{}) Slice {
	var s Slice

	s.init(slice)

	return s
}

// FromSlice gives generic slice representation of s.
func FromSlice(s Slice) []interface{} {
	return s.slice()
}

type Primitive struct {
	Value interface{}
}

// PrimitiveSlice is a workaround for hcl.DecodeObject,
// which always appends to existing slices,
// thus making the output of DecodeObject
// non-idempotent, as it always doubles
// any slices values.
//
// Wrapping a slice value with ToSlice
// prevents from doubling the items
// on hcl.DecodeObject.
//
// NOTE(rjeczalik): Each element v is wrapped
// with map[string]interface{"": v} in order
// to ensure HCL classifies the Slice
// as *ast.ObjectList. If element v is
// a primitive, HCL would consider Slice
// as a *ast.ListType, which would would
// break hcl.DecodeObject. Hacks ¯\_(ツ)_/¯.
type PrimitiveSlice map[string]Primitive

var (
	_ json.Marshaler   = new(PrimitiveSlice)
	_ json.Unmarshaler = new(PrimitiveSlice)
)

func (s *PrimitiveSlice) init(v []interface{}) {
	*s = make(PrimitiveSlice, len(v))

	for i := range v {
		(*s)[strconv.Itoa(i)] = Primitive{Value: v[i]}
	}
}

func (s PrimitiveSlice) slice() []interface{} {
	max := 0
	slice := make([]interface{}, len(s))

	for k, v := range s {
		i, err := strconv.Atoi(k)
		if err != nil {
			// HCL's decoder errornously merges object's keys
			// into the slice. In order to make it working,
			// we just ignore them.
			continue
		}

		slice[i] = v.Value

		if i > max {
			max = i
		}
	}

	return slice[:max+1]
}

// MarshalJSON implements the json.Marshaler interface.
func (s PrimitiveSlice) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.slice())
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (s *PrimitiveSlice) UnmarshalJSON(p []byte) error {
	var slice []interface{}

	if err := json.Unmarshal(p, &slice); err != nil {
		return err
	}

	s.init(slice)

	return nil
}

// ToPrimitiveSlice creates a Slice value out of slice argument.
func ToPrimitiveSlice(slice []interface{}) PrimitiveSlice {
	var s PrimitiveSlice

	s.init(slice)

	return s
}

// FromPrimitiveSlice gives generic slice representation of s.
func FromPrimitiveSlice(s PrimitiveSlice) []interface{} {
	return s.slice()
}
