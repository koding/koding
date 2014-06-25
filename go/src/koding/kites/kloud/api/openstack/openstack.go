package api

import (
	"errors"
	"fmt"
	"log"
	"strings"

	"github.com/mitchellh/mapstructure"
	"github.com/rackspace/gophercloud"
)

type Openstack struct {
	AuthURL  string
	Provider string
	Client   gophercloud.CloudServersProvider

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

func New(authURL, providerName string, credential, builder map[string]interface{}) (*Openstack, error) {
	// OpenStack's auto-generated openrc.sh files do not append the suffix
	// /tokens to the authentication URL. This ensures it is present when
	// specifying the URL.
	if strings.Contains(authURL, "://") && !strings.HasSuffix(authURL, "/tokens") {
		authURL += "/tokens"
	}

	o := &Openstack{
		AuthURL:  authURL,
		Provider: providerName,
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

	if o.Creds.Password == "" && o.Creds.ApiKey == "" {
		return nil, errors.New("Password/ApiKey is not set")
	}

	authoptions := gophercloud.AuthOptions{
		AllowReauth: true,
		ApiKey:      o.Creds.ApiKey,
		TenantId:    o.Creds.TenantId,
		TenantName:  o.Creds.TenantName,
		Username:    o.Creds.Username,
		Password:    o.Creds.Password,
	}

	access, err := gophercloud.Authenticate(authURL, authoptions)
	if err != nil {
		return nil, err
	}

	fmt.Printf("user %+v\n", access.User)
	fmt.Printf("token %+v\n", access.Token)
	fmt.Printf("providerName %+v\n", providerName)

	//fetches the api requisites from gophercloud for the appropriate
	//openstack variant
	api, err := gophercloud.PopulateApi(providerName)
	if err != nil {
		return nil, err
	}

	if o.Builder.RawRegion != "" {
		api.Region = o.Builder.RawRegion
	}

	csp, err := gophercloud.ServersApi(access, api)
	if err != nil {
		log.Printf("Region: %s", o.Builder.RawRegion)
		return nil, err
	}
	o.Client = csp

	return o, nil
}
