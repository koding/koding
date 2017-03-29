package object

import "fmt"

// FixYAML is a best-effort of fixing representation of
// YAML-encoded value, so it can be marshaled to a valid JSON.
//
// YAML creates types like map[interface{}]interface{}, which are
// not a valid JSON types.
//
// Related issue:
//
//   https://github.com/go-yaml/yaml/issues/139
//
func FixYAML(v interface{}) interface{} {
	switch v := v.(type) {
	case map[string]interface{}:
		for k, w := range v {
			v[k] = FixYAML(w)
		}

		return v
	case map[interface{}]interface{}:
		fixedV := make(map[string]interface{}, len(v))

		for k, v := range v {
			fixedV[fmt.Sprintf("%v", k)] = FixYAML(v)
		}

		return fixedV
	case []interface{}:
		fixedV := make([]interface{}, len(v))

		for i := range v {
			fixedV[i] = FixYAML(v[i])
		}

		return fixedV
	default:
		return v
	}
}

// FixHCL is a best-effort method to "fix" value representation of
// HCL-encoded value, so it can be marshaled to a valid JSON.
//
// hcl.Unmarshal encodes each object as []map[string]interface{},
// and kloud expects JSON objects to not be wrapped in a 1-element
// slice.
//
// This function converts []map[string]interface{} to map[string]interface{}
// if length of the slice is 1.
//
// BUG(rjeczalik): This is going to break templates, which have legit
// 1-element []map[string]interface{} values.
func FixHCL(v interface{}) {
	cur, ok := v.(map[string]interface{})
	if !ok {
		return
	}

	stack := []map[string]interface{}{cur}

	for len(stack) != 0 {
		cur, stack = stack[0], stack[1:]

		for key, val := range cur {
			switch val := val.(type) {
			case []map[string]interface{}:
				if len(val) == 1 {
					cur[key] = val[0]
				}

				for _, val := range val {
					stack = append(stack, val)
				}
			case []interface{}:
				if len(val) == 1 {
					if vval, ok := val[0].(map[string]interface{}); ok {
						cur[key] = vval
					}
				}

				for _, val := range val {
					if vval, ok := val.(map[string]interface{}); ok {
						stack = append(stack, vval)
					}
				}

			case map[string]interface{}:
				stack = append(stack, val)
			}
		}
	}
}
