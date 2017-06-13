package providertest

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"reflect"

	"github.com/kylelemons/godebug/pretty"
)

func mask(v interface{}, fn func(string) string) error {
	switch t := v.(type) {
	case map[string]interface{}:
		for key, val := range t {
			if s := fn(key); s != "" {
				t[key] = s
				continue
			}

			mask(val, fn)
		}
	case []interface{}:
		for _, val := range t {
			mask(val, fn)
		}
	}

	return nil
}

func Write(file, content string, fn func(string) string) error {
	var v interface{}

	if err := json.Unmarshal([]byte(content), &v); err != nil {
		return err
	}

	if err := mask(v, fn); err != nil {
		return err
	}

	p, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		return err
	}

	return ioutil.WriteFile(file, p, 0644)
}

func Equal(got, want string, fn func(string) string) error {
	var v1, v2 interface{}

	if err := json.Unmarshal([]byte(got), &v1); err != nil {
		return fmt.Errorf(`failed to parse "got" JSON: %s`, err)
	}

	if err := json.Unmarshal([]byte(want), &v2); err != nil {
		return fmt.Errorf(`failed to parse "want" JSON: %s`, err)
	}

	if fn != nil {
		if err := mask(v1, fn); err != nil {
			return err
		}

		if err := mask(v2, fn); err != nil {
			return err
		}
	}

	if !reflect.DeepEqual(v1, v2) {
		return fmt.Errorf("templates not equal:\n%s\n", pretty.Compare(v2, v1))
	}

	return nil
}
