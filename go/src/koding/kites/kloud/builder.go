package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"

	"github.com/koding/kite"
)

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	Prepare(...interface{}) error
	Build(...interface{}) error
}

// Controller manages a machine
type Controller interface {
	// Setup is needed to initialize the Controller. It should be called before
	// calling the other interface methods
	Setup(...interface{}) error

	// Start starts the machine
	Start(...interface{}) error

	// Stop stops the machine
	Stop(...interface{}) error

	// Restart restarts the machine
	Restart(...interface{}) error

	// Destroy destroys the machine
	Destroy(...interface{}) error
}

type buildArgs struct {
	Provider   string
	Credential map[string]interface{}
	Builder    map[string]interface{}
}

var providers = map[string]interface{}{
	"digitalocean": &DigitalOcean{},
}

func build(r *kite.Request) (interface{}, error) {
	args := &buildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	p, ok := providers[args.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	provider, ok := p.(Builder)
	if !ok {
		return nil, errors.New("provider doesn't satisfy/support this method.")
	}

	if err := provider.Prepare(args.Credential, args.Builder); err != nil {
		return nil, err
	}

	if err := provider.Build(); err != nil {
		return nil, err
	}

	return true, nil
}

// templateData includes our klient converts the given raw interface to a
// []byte data that can used to pass into packer.Template().
func templateData(raw interface{}) ([]byte, error) {
	rawMapData, err := toMap(raw, "mapstructure")
	if err != nil {
		return nil, err
	}

	packerTemplate := map[string]interface{}{}
	packerTemplate["builders"] = []interface{}{rawMapData}
	packerTemplate["provisioners"] = klientProvisioner

	return json.Marshal(packerTemplate)
}

// toMap converts a struct defined by `in` to a map[string]interface{}. It only
// extract data that is defined by the given tag.
func toMap(in interface{}, tag string) (map[string]interface{}, error) {
	out := make(map[string]interface{})

	v := reflect.ValueOf(in)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}

	// we only accept structs
	if v.Kind() != reflect.Struct {
		return nil, fmt.Errorf("only struct is allowd got %T", v)
	}

	typ := v.Type()
	for i := 0; i < v.NumField(); i++ {
		// gets us a StructField
		fi := typ.Field(i)
		if tagv := fi.Tag.Get(tag); tagv != "" {
			// set key of map to value in struct field
			out[tagv] = v.Field(i).Interface()
		}
	}
	return out, nil

}
