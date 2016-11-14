package providertest

import (
  "encoding/json"
  "fmt"
  "reflect"
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

func Equal(got, want string, fn func(string) string) error {
	var v1, v2 interface{}

	if err := json.Unmarshal([]byte(got), &v1); err != nil {
		return err
	}

	if err := json.Unmarshal([]byte(want), &v2); err != nil {
		return err
	}

  if err := mask(v1, fn); err != nil {
    return err
  }

  if err := mask(v2, fn); err != nil {
    return err
  }

	if !reflect.DeepEqual(v1, v2) {
		p1, err := json.MarshalIndent(v1, "", "\t")
		if err != nil {
			panic(err)
		}

		p2, err := json.MarshalIndent(v2, "", "\t")
		if err != nil {
			panic(err)
		}

		return fmt.Errorf("got:\n%s\nwant:\n%s\n", p1, p2)
	}

	return nil
}
