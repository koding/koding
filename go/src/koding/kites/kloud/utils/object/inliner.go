package object

import (
	"encoding/json"
	"fmt"

	"gopkg.in/mgo.v2/bson"
)

// NOTE(rjeczalik): Inliner is not suitable to inline large values (>1MB)

type (
	InlineFirst  interface{}
	InlineSecond interface{}
)

// TODO(rjeczalik): inlining YAML may not work correctly
// due to:
//
//   https://github.com/go-yaml/yaml/issues/55
//
// Either add workaround, like the one for BSON, or fix YAML package.
type Inliner struct {
	InlineFirst  `bson:",inline" yaml:",inline"`
	InlineSecond `bson:",inline" yaml:",inline"`
}

func Inline(v1, v2 interface{}) *Inliner {
	return &Inliner{
		InlineFirst:  v1,
		InlineSecond: v2,
	}
}

var (
	_ json.Marshaler   = (*Inliner)(nil)
	_ json.Unmarshaler = (*Inliner)(nil)
	_ bson.Getter      = (*Inliner)(nil)
	_ bson.Setter      = (*Inliner)(nil)
)

func (in *Inliner) MarshalJSON() ([]byte, error) {
	obj, err := in.Inline()
	if err != nil {
		return nil, err
	}

	return json.Marshal(obj)
}

func (in *Inliner) UnmarshalJSON(p []byte) error {
	if err := json.Unmarshal(p, in.FirstAddr()); err != nil {
		return err
	}

	return json.Unmarshal(p, in.SecondAddr())
}

func (in *Inliner) String() string {
	return fmt.Sprintf("{first: %#v, second: %#v}", in.InlineFirst, in.InlineSecond)
}

func (in *Inliner) Inline() (Object, error) {
	first, err := ToJSON(in.InlineFirst)
	if err != nil {
		return nil, err
	}

	second, err := ToJSON(in.InlineSecond)
	if err != nil {
		return nil, err
	}

	for k, v := range second {
		if _, ok := first[k]; !ok {
			first[k] = v
		}
	}

	return Object(first), nil
}

// GetBSON is a workaround for bson.Marshal not allowing
// for pointers to structs with ,inline option.
// It fails with:
//
//   Option ,inline needs a struct value or map field
//
// It should eventually be fixed and workaround dropped.
func (in *Inliner) GetBSON() (interface{}, error) {
	first, err := ToBSON(in.InlineFirst)
	if err != nil {
		return nil, err
	}

	second, err := ToBSON(in.InlineSecond)
	if err != nil {
		return nil, err
	}

	for k, v := range second {
		if _, ok := first[k]; !ok {
			first[k] = v
		}
	}

	return Object(first), nil
}

// SetBSON is a workaround for bson.Marshal not allowing
// for pointers to structs with ,inline option.
// It fails with:
//
//   Option ,inline needs a struct value or map field
//
// It should eventually be fixed and workaround dropped.
func (in *Inliner) SetBSON(raw bson.Raw) error {
	if err := raw.Unmarshal(in.SecondAddr()); err != nil {
		return err
	}

	return raw.Unmarshal(in.FirstAddr())
}

func (in *Inliner) FirstAddr() interface{} {
	return ToAddr(in.InlineFirst)
}

func (in *Inliner) SecondAddr() interface{} {
	return ToAddr(in.InlineSecond)
}

func ToAddr(v interface{}) interface{} {
	switch v := v.(type) {
	case map[string]interface{}:
		return &v
	case []interface{}:
		return &v
	case []map[string]interface{}:
		return &v
	default:
		return v
	}
}

func ToJSON(v interface{}) (obj Object, err error) {
	p, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}

	if err := json.Unmarshal(p, &obj); err != nil {
		return nil, err
	}

	return obj, nil
}

func ToBSON(v interface{}) (obj Object, err error) {
	p, err := bson.Marshal(v)
	if err != nil {
		return nil, err
	}

	if err := bson.Unmarshal(p, &obj); err != nil {
		return nil, err
	}

	return obj, nil
}
