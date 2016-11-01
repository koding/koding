package main

import (
	"encoding/json"
	"log"
	"os"

	"koding/kites/kloud/stack/provider"
)

type SchemaConfig struct {
	GenSchema string `required:"true"`
}

func genSchema(file string) error {
	f, err := os.Create(file)
	if err != nil {
		return err
	}

	enc := json.NewEncoder(f)
	enc.SetIndent("", "\t")

	if err := nonil(enc.Encode(provider.Desc()), f.Close()); err != nil {
		return nonil(err, os.Remove(f.Name()))
	}

	log.Printf("Provider schema was written successfully to %s.", f.Name())

	return nil
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
