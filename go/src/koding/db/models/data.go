package models

import (
	"strings"
)

// Data holds arbitrary key value.
type Data map[string]interface{}

// GetString returns value as string with given key
func (d Data) GetString(key string) (string, error) {
	dt, err := d.Get(key)
	if err != nil {
		return "", err
	}

	s, ok := dt.(string)
	if !ok {
		return "", ErrDataInvalidType
	}

	return s, nil
}

// GetData returns value as models.Data with given key
func (d Data) GetData(key string) (*Data, error) {
	dt, err := d.Get(key)
	if err != nil {
		return nil, err
	}

	s, ok := dt.(*Data)
	if !ok {
		return nil, ErrDataInvalidType
	}

	return s, nil
}

// Get returns value with given key
func (d Data) Get(key string) (interface{}, error) {
	dt, ok := findPath(d, strings.Split(key, ".")...)
	if !ok {
		return "", ErrDataKeyNotExists
	}

	return dt, nil
}

func findPath(data Data, path ...string) (interface{}, bool) {
	if len(path) == 0 {
		return nil, false
	}
	key := path[0]
	dt, ok := data[key]
	if !ok {
		return nil, false
	}

	if len(path) == 1 {
		return dt, true
	}

	next, ok := dt.(Data)
	if !ok {
		return nil, false
	}

	return findPath(next, path[1:]...)
}
