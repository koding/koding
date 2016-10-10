package azure

import (
	"errors"
	"fmt"
	"strings"

	"github.com/satori/go.uuid"

	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/userdata"
)

type Endpoint struct {
	Name        string `hcl:"name"`
	Protocol    string `hcl:"protocol"`
	PublicPort  int    `hcl:"public_port"`
	PrivatePort int    `hcl:"private_port"`
}

var vmKlient = &Endpoint{
	Name:        "klient",
	Protocol:    "tcp",
	PublicPort:  56789,
	PrivatePort: 56789,
}

var vmSSH = &Endpoint{
	Name:        "ssh",
	Protocol:    "tcp",
	PublicPort:  22,
	PrivatePort: 22,
}

func endpointsIndex(endpoints []interface{}, name string) int {
	for i, v := range endpoints {
		endpoint, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		s, ok := endpoint["name"].(string)
		if !ok {
			continue
		}

		if strings.EqualFold(s, name) {
			return i
		}
	}

	return -1
}

func (s *Stack) InjectAzureData() (stackplan.KiteMap, error) {
	t := s.Builder.Template

	meta := s.Cred()

	if meta == nil {
		return nil, errors.New("no Azure credentials found")
	}

	if err := meta.BootstrapValid(); err != nil {
		return nil, fmt.Errorf("invalid bootstrap metadata for %q: %s", s.c.Identifier, err)
	}

	var res struct {
		AzureInstance map[string]map[string]interface{} `hcl:"azure_instance"`
	}

	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	if len(res.AzureInstance) == 0 {
		return nil, errors.New("no Azure instance found")
	}

	kiteIDs := make(stackplan.KiteMap)

	for name, vm := range res.AzureInstance {
		// Set defaults from bootstrapped metadata.

		if s, ok := vm["hosted_service_name"]; !ok || s == "" {
			vm["hosted_service_name"] = meta.HostedServiceID
		}

		if s, ok := vm["storage_service_name"]; !ok || s == "" {
			vm["storage_service_name"] = meta.StorageServiceID
		}

		if s, ok := vm["security_group"]; !ok || s == "" {
			vm["security_group"] = meta.SecurityGroupID
		}

		if s, ok := vm["virtual_network"]; !ok || s == "" {
			vm["virtual_network"] = meta.VirtualNetworkID
		}

		if s, ok := vm["subnet"]; !ok || s == "" {
			vm["subnet"] = meta.SubnetName
		}

		if s, ok := vm["location"]; !ok || s == "" {
			vm["location"] = meta.Location
		}

		if u, ok := vm["username"]; !ok || u == "" {
			vm["username"] = s.Req.Username
		}

		endpoints, ok := vm["endpoint"].([]interface{})
		if !ok {
			endpoints = make([]interface{}, 0, 2)
		}

		// Ensure klient port is exposed.
		if i := endpointsIndex(endpoints, vmKlient.Name); i != -1 {
			endpoints[i] = vmKlient
		} else {
			endpoints = append(endpoints, vmKlient)
		}

		// Look for SSH endpoint and add a default one
		// if it was not specified.
		if i := endpointsIndex(endpoints, vmSSH.Name); i == -1 {
			endpoints = append(endpoints, vmSSH)
		}

		vm["endpoint"] = endpoints

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups:   []string{"sudo"},
			Hostname: s.Req.Username, // no typo here. hostname = username
		}

		s.Builder.InterpolateField(vm, name, "custom_data")

		if b, ok := vm["debug"].(bool); ok && b {
			s.Debug = true
			delete(vm, "debug")
		}

		if s, ok := vm["custom_data"].(string); ok {
			userCfg.UserData = s
		}

		kiteID := uuid.NewV4().String()

		kiteKey, err := s.Session.Userdata.Keycreator.Create(s.Req.Username, kiteID)
		if err != nil {
			return nil, err
		}

		userCfg.KiteKey = kiteKey

		userdata, err := s.Session.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		vm["user_data"] = string(userdata)

		res.AzureInstance[name] = vm
		kiteIDs[name] = kiteID
	}

	t.Resource["azure_instance"] = res.AzureInstance

	if err := t.Flush(); err != nil {
		return nil, err
	}

	if err := t.ShadowVariables("FORBIDDEN", "azure_publish_settings", "azure_settings_file"); err != nil {
		return nil, err
	}

	return kiteIDs, nil
}
