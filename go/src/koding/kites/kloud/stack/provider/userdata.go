package provider

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/metadata"
	"koding/kites/kloud/stack"
)

// BuildUserdata builds a Userdata value for the given named vm.
//
// The vm is a Terraform resource value.
func (bs *BaseStack) BuildUserdata(name string, vm map[string]interface{}) error {
	count := 1
	t := bs.Builder.Template

	if n, ok := vm["count"].(int); ok && n > 1 {
		count = n
	}

	kiteKeyName := "kitekeys_" + name
	kiteKeys := make(map[int]string, count)

	if s, ok := vm["koding_klient_timeout"].(string); ok {
		d, err := time.ParseDuration(s)
		if err != nil {
			return errors.New(`unable to read "koding_klient_timeout": ` + err.Error())
		}

		bs.Planner.KlientTimeout = d

		delete(vm, "koding_klient_timeout")
	}

	var labels []string
	if count > 1 {
		for i := 0; i < count; i++ {
			labels = append(labels, fmt.Sprintf("%s.%d", name, i))
		}
	} else {
		labels = append(labels, name)
	}

	field := bs.Provider.userdata()

	cfg := &metadata.Config{
		Konfig:  stack.Konfig,
		KiteKey: "${lookup(var." + kiteKeyName + ", count.index)}",
	}

	if b, ok := vm["koding_debug"].(bool); ok {
		cfg.Debug = b
		bs.Debug = b
		delete(vm, "koding_debug")
	}

	if v, ok := vm["koding_mounts"]; ok {
		cfg.Exports = tomap(v)
		delete(vm, "koding_mounts")
	}

	var meta map[string]interface{}

	if b, ok := vm["koding_always_on"].(bool); ok {
		meta = map[string]interface{}{
			"alwaysOn": b,
		}
		delete(vm, "koding_always_on")
	}

	if s, ok := vm[field].(string); ok {
		cfg.Userdata = s
	}

	ci, err := metadata.New(cfg)
	if err != nil {
		return err
	}

	vm[field] = ci.String()

	// create independent kiteKey for each machine and create a Terraform
	// lookup map, which is used in conjunction with the `count.index`.
	for i, label := range labels {
		kiteKey, err := bs.BuildKiteKey(label, bs.Req.Username)
		if err != nil {
			return err
		}

		kiteKeys[i] = kiteKey

		if len(meta) != 0 {
			bs.Metas[label] = meta
		}
	}

	t.Variable[kiteKeyName] = map[string]interface{}{
		"default": kiteKeys,
	}

	return nil
}

// TODO(rjeczalik): move to utils/object package
func tomap(v interface{}) map[string]string {
	m := make(map[string]string)

	switch v := v.(type) {
	case []map[string]interface{}:
		for _, v := range v {
			mergemap(m, v)
		}
	case []map[interface{}]interface{}:
		for _, v := range v {
			mergemap(m, v)
		}
	case []interface{}:
		for _, v := range v {
			mergemap(m, v)
		}
	default:
		mergemap(m, v)
	}

	return m
}

func mergemap(m map[string]string, v interface{}) {
	switch v := v.(type) {
	case map[string]string:
		for k, v := range v {
			m[k] = v
		}
	case map[string]interface{}:
		for k, v := range v {
			m[k] = tostring(v)
		}
	case map[interface{}]interface{}:
		for k, v := range v {
			m[tostring(k)] = tostring(v)
		}
	}
}

func tostring(v interface{}) string {
	switch v := v.(type) {
	case string:
		return v
	case fmt.Stringer:
		return v.String()
	default:
		return fmt.Sprintf("%v", v)
	}
}
