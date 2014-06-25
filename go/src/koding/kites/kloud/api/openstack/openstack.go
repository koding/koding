package api

import (
	"errors"
	"fmt"
	"strings"

	"github.com/mitchellh/mapstructure"
	"launchpad.net/goose/identity"
)

type Openstack struct {
	AuthURL  string `mapstructure:"authURL"`
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

func New(authURL string, credential, builder map[string]interface{}) (*Openstack, error) {
	o := Openstack{
		AuthURL: authURL,
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

	// If we have ApiKey use that. If the user has provided a Password use that
	// instead of the ApiKey. TODO: make it more smarter or choosable from user
	// perspective.
	secret := o.Creds.ApiKey
	authMode := identity.AuthKeyPair
	if o.Creds.Password != "" {
		secret = o.Creds.Password
		authMode = identity.AuthUserPass
	}

	// OpenStack's auto-generated openrc.sh files do not append the suffix
	// /tokens to the authentication URL. This ensures it is present when
	// specifying the URL.
	if strings.Contains(authURL, "://") && !strings.HasSuffix(authURL, "/tokens") {
		authURL += "/tokens"
	}

	creds := &identity.Credentials{
		URL:        authURL,
		User:       o.Creds.Username,
		Secrets:    secret,
		TenantName: o.Creds.TenantName,
	}

	// Get an authenticator and authenticate with the credentials above
	authenticator := identity.NewAuthenticator(authMode, nil)
	credentials, err := authenticator.Auth(creds)
	if err != nil {
		return nil, err
	}

	fmt.Printf("credentials %+v\n", credentials)
	return nil, nil
}
