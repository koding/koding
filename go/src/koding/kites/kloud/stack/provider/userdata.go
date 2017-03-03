package provider

import (
	"fmt"

	"koding/kites/kloud/userdata"
)

// Userdata describes generic stack data required
// to deploy and run a klient service.
type Userdata struct {
	Count       int            `json:"count" hcl:"count"` // number of instances
	Debug       bool           `json:"debug" hcl:"debug"` // whether start klient in debug mode
	KiteKeyName string         `json:"-" hcl:"-"`         // variable name of kitekey list
	KiteKeys    map[int]string `json:"-" hcl:"-"`         // kite keys
}

// BuildUserdata builds a Userdata value for the given named vm.
//
// The vm is a Terraform resource value.
func (bs *BaseStack) BuildUserdata(name string, vm map[string]interface{}) (*Userdata, error) {
	ud := &Userdata{
		Count:       1,
		KiteKeyName: "kitekeys_" + name,
	}

	if n, ok := vm["count"].(int); ok && n > 1 {
		ud.Count = n
	}

	ud.KiteKeys = make(map[int]string, ud.Count)

	if b, ok := vm["debug"].(bool); ok {
		ud.Debug = b
		delete(vm, "debug")
	}

	var labels []string
	if ud.Count > 1 {
		for i := 0; i < ud.Count; i++ {
			labels = append(labels, fmt.Sprintf("%s.%d", name, i))
		}
	} else {
		labels = append(labels, name)
	}

	field := bs.Provider.userdata()

	bs.Builder.InterpolateField(vm, name, field)

	// this part will be the same for all machines
	userCfg := &userdata.CloudInitConfig{
		Username: bs.Req.Username,
		Groups:   []string{"sudo"},
		Hostname: bs.Req.Username, // no typo here. hostname = username
		KiteKey:  "${lookup(var." + ud.KiteKeyName + ", count.index)}",
	}

	if s, ok := vm[field].(string); ok {
		userCfg.UserData = s
	}

	userdata, err := bs.Session.Userdata.Create(userCfg)
	if err != nil {
		return nil, err
	}

	vm[field] = string(userdata)

	// create independent kiteKey for each machine and create a Terraform
	// lookup map, which is used in conjunction with the `count.index`.
	for i, label := range labels {
		kiteKey, err := bs.BuildKiteKey(label, bs.Req.Username)
		if err != nil {
			return nil, err
		}

		ud.KiteKeys[i] = kiteKey
	}

	return ud, nil
}
