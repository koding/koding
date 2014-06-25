package api

import (
	"errors"
	"strings"

	"github.com/mitchellh/mapstructure"
	"github.com/rackspace/gophercloud"
)

const (
	ApiKey = "96d6388ccb936f047fd35eb29c36df17"
)

type Openstack struct {
	Provider string `mapstructure:"provider"`
	Insecure bool   `mapstructure:"insecure"`

	Creds struct {
		Username   string `mapstructure:"username"`
		Password   string `mapstructure:"password"`
		ApiKey     string `mapstructure:"apiKey"`
		TenantName string `mapstructure:"tenant_name"`
		TenantId   string `mapstructure:"tenant_id"`
	}

	Builder struct {
		SourceImage       string   `mapstructure:"source_image"`
		Flavor            string   `mapstructure:"flavor"`
		RawRegion         string   `mapstructure:"region"`
		RawSSHTimeout     string   `mapstructure:"ssh_timeout"`
		SSHUsername       string   `mapstructure:"ssh_username"`
		SSHPort           int      `mapstructure:"ssh_port"`
		OpenstackProvider string   `mapstructure:"openstack_provider"`
		UseFloatingIp     bool     `mapstructure:"use_floating_ip"`
		FloatingIpPool    string   `mapstructure:"floating_ip_pool"`
		FloatingIp        string   `mapstructure:"floating_ip"`
		SecurityGroups    []string `mapstructure:"security_groups"`
	}
}

func New(provider string, credential, builder map[string]interface{}) (*Openstack, error) {
	o := Openstack{
		Provider: provider,
	}

	// Credentials
	if err := mapstructure.Decode(credential, &o.Creds); err != nil {
		return nil, err
	}

	// Builder data
	if err := mapstructure.Decode(builder, &o.Builder); err != nil {
		return nil, err
	}

	if o.Creds.Username == "" {
		return nil, errors.New("Username is not set")
	}

	if o.Creds.Password == "" {
		return nil, errors.New("Password is not set")
	}

	// OpenStack's auto-generated openrc.sh files do not append the suffix
	// /tokens to the authentication URL. This ensures it is present when
	// specifying the URL.
	if strings.Contains(provider, "://") && !strings.HasSuffix(provider, "/tokens") {
		o.Provider += "/tokens"
	}

	authoptions := gophercloud.AuthOptions{
		AllowReauth: true,
		ApiKey:      o.Creds.ApiKey,
		TenantId:    o.Creds.TenantId,
		TenantName:  o.Creds.TenantName,
		Username:    o.Creds.Username,
		Password:    o.Creds.Password,
	}

	return nil, nil
}
