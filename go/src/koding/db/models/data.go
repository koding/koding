package models

import (
	"strings"
)

// Data holds arbitrary key value.
type Data map[string]interface{}

// GetString returns value as string with given key
func (d *Data) GetString(key string) (string, error) {
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

// Get returns value with given key
func (d *Data) Get(key string) (interface{}, error) {
	if d == nil {
		return "", ErrDataKeyNotExists
	}

	dt, ok := findPath(strings.Split(key, "."), *d)
	if !ok {
		return "", ErrDataKeyNotExists
	}

	return dt, nil
}

func findPath(path []string, data Data) (interface{}, bool) {
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

	return findPath(path[1:], next)
}
