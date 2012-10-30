package dnode

import (
	"encoding/json"
	"errors"
	"reflect"
)

type Partial struct {
	Raw       []byte
	callbacks []CallbackSpec
}

func (p *Partial) MarshalJSON() ([]byte, error) {
	return p.Raw, nil
}

func (p *Partial) UnmarshalJSON(data []byte) error {
	if p == nil {
		return errors.New("json.Partial: UnmarshalJSON on nil pointer")
	}
	p.Raw = append(p.Raw[0:0], data...)
	return nil
}

func (p *Partial) Unmarshal(v interface{}) error {
	err := json.Unmarshal(p.Raw, v)
	if err != nil {
		return err
	}
	value := reflect.ValueOf(v)
	for _, callback := range p.callbacks {
		err := callback.Apply(value)
		if err != nil {
			return err
		}
	}
	return nil
}

func (p *Partial) Array() ([]interface{}, error) {
	var a []interface{}
	err := p.Unmarshal(&a)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func (p *Partial) Map() (map[string]interface{}, error) {
	var m map[string]interface{}
	err := p.Unmarshal(&m)
	if err != nil {
		return nil, err
	}
	return m, nil
}
