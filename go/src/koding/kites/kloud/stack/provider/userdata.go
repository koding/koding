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
	useEmbedded := 0

	if b, ok := vm["koding_use_embedded"].(bool); ok && b {
		useEmbedded = 1
	}
	t.Variable["koding_use_embedded"] = map[string]interface{}{
		"default": useEmbedded,
	}
	delete(vm, "koding_use_embedded")

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

	if s, ok := vm[field].(string); ok {
		cfg.Userdata = s
	}

	ci, err := metadata.New(cfg)
	if err != nil {
		return err
	}

	vm[field] = ci.String()

	bs.Builder.InterpolateField(vm, name, field)

	// create independent kiteKey for each machine and create a Terraform
	// lookup map, which is used in conjunction with the `count.index`.
	for i, label := range labels {
		kiteKey, err := bs.BuildKiteKey(label, bs.Req.Username)
		if err != nil {
			return err
		}

		kiteKeys[i] = kiteKey
	}

	t.Variable[kiteKeyName] = map[string]interface{}{
		"default": kiteKeys,
	}

	return nil
}
