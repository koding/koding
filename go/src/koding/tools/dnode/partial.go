package dnode

import (
	"encoding/json"
	"errors"
	"reflect"
)

// Partial is the type of "arguments" field in dnode.Message.
type Partial struct {
	Raw       []byte
	Callbacks []CallbackSpec
}

// MarshalJSON returns the raw bytes of the Partial.
func (p *Partial) MarshalJSON() ([]byte, error) {
	return p.Raw, nil
}

// UnmarshalJSON puts the data into Partial.Raw.
func (p *Partial) UnmarshalJSON(data []byte) error {
	if p == nil {
		return errors.New("json.Partial: UnmarshalJSON on nil pointer")
	}
	p.Raw = append(p.Raw[0:0], data...)
	return nil
}

// Unmarshal unmarshals the data (v) into p.Raw and calls all the
// callbacks with the value of v.
func (p *Partial) Unmarshal(v interface{}) error {
	err := json.Unmarshal(p.Raw, v)
	if err != nil {
		return err
	}
	value := reflect.ValueOf(v)
	for _, callback := range p.Callbacks {
		err := callback.Apply(value)
		if err != nil {
			return err
		}
	}
	return nil
}

// Array is a helper method that returns a []interface{}
// by unmarshalling the Partial.
func (p *Partial) Array() ([]interface{}, error) {
	var a []interface{}
	err := p.Unmarshal(&a)
	if err != nil {
		return nil, err
	}
	return a, nil
}

// Array is a helper method that returns a map[string]interface{}
// by unmarshalling the Partial.
func (p *Partial) Map() (map[string]interface{}, error) {
	var m map[string]interface{}
	err := p.Unmarshal(&m)
	if err != nil {
		return nil, err
	}
	return m, nil
}
