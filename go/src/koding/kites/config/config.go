// This file is auto-generated. DO NOT EDIT!

package config

import (
	"text/template"

	"github.com/koding/logging"
)

var DefaultConfig = &Config{
	Environment: defaultAliases.Get("default", "development"),
	Log:         logging.NewLogger("config"),
	Host2ip: map[string]string{
		"dev.koding.com": "127.0.0.1",
	},

	tmpls: map[string]*template.Template{
		`buckets.publicLogs`:     template.Must(template.New(`buckets.publicLogs`).Parse(`{"name":"kodingdev-publiclogs","region":"us-east-1"}`)),
		`endpoints.ip`:           template.Must(template.New(`endpoints.ip`).Parse(`"https://dev-p2.koding.com/-/ip"`)),
		`endpoints.ipCheck`:      template.Must(template.New(`endpoints.ipCheck`).Parse(`"https://dev-p2.koding.com/-/ipcheck"`)),
		`endpoints.kdLatest`:     template.Must(template.New(`endpoints.kdLatest`).Parse(`"https://koding-kd.s3.amazonaws.com/development/latest-version.txt"`)),
		`endpoints.klientLatest`: template.Must(template.New(`endpoints.klientLatest`).Parse(`"https://koding-klient.s3.amazonaws.com/{{.Environment}}/latest-version.txt"`)),
		`endpoints.kloud`:        template.Must(template.New(`endpoints.kloud`).Parse(`"https://sandbox.koding.com/kloud/kite"`)),
		`endpoints.kontrol`:      template.Must(template.New(`endpoints.kontrol`).Parse(`"https://sandbox.koding.com/kontrol/kite"`)),
		`endpoints.tunnelServer`: template.Must(template.New(`endpoints.tunnelServer`).Parse(`"http://dev-t.koding.com/kite"`)),
	},
}

// PublicLogsBucket returns bucket stored in publicLogs variable.
func (c *Config) PublicLogsBucket(env string) (*Bucket, error) {
	return c.GetBucket("buckets.publicLogs", c.GetEnvironment(env))
}

// PublicLogsBucket returns bucket stored in publicLogs variable.
//
// PublicLogsBucket is a wrapper around DefaultConfig.PublicLogsBucket.
func PublicLogsBucket(env string) (*Bucket, error) {
	return DefaultConfig.PublicLogsBucket(env)
}

// MustPublicLogsBucket returns bucket stored in publicLogs variable. It panics in case of error.
func (c *Config) MustPublicLogsBucket(environment string) *Bucket {
	val, err := c.PublicLogsBucket(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustPublicLogsBucket returns bucket stored in publicLogs variable.
//
// MustPublicLogsBucket is a wrapper around DefaultConfig.MustPublicLogsBucket.
func MustPublicLogsBucket(env string) *Bucket {
	return DefaultConfig.MustPublicLogsBucket(env)
}

// IpURL returns endpoint stored in ip variable.
func (c *Config) IpURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.ip", c.GetEnvironment(env))
}

// IpURL returns endpoint stored in ip variable.
//
// IpURL is a wrapper around DefaultConfig.IpURL.
func IpURL(env string) (string, error) {
	return DefaultConfig.IpURL(env)
}

// MustIpURL returns endpoint stored in ip variable. It panics in case of error.
func (c *Config) MustIpURL(environment string) string {
	val, err := c.IpURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustIpURL returns endpoint stored in ip variable.
//
// MustIpURL is a wrapper around DefaultConfig.MustIpURL.
func MustIpURL(env string) string {
	return DefaultConfig.MustIpURL(env)
}

// IpCheckURL returns endpoint stored in ipCheck variable.
func (c *Config) IpCheckURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.ipCheck", c.GetEnvironment(env))
}

// IpCheckURL returns endpoint stored in ipCheck variable.
//
// IpCheckURL is a wrapper around DefaultConfig.IpCheckURL.
func IpCheckURL(env string) (string, error) {
	return DefaultConfig.IpCheckURL(env)
}

// MustIpCheckURL returns endpoint stored in ipCheck variable. It panics in case of error.
func (c *Config) MustIpCheckURL(environment string) string {
	val, err := c.IpCheckURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustIpCheckURL returns endpoint stored in ipCheck variable.
//
// MustIpCheckURL is a wrapper around DefaultConfig.MustIpCheckURL.
func MustIpCheckURL(env string) string {
	return DefaultConfig.MustIpCheckURL(env)
}

// KdLatestURL returns endpoint stored in kdLatest variable.
func (c *Config) KdLatestURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.kdLatest", c.GetEnvironment(env))
}

// KdLatestURL returns endpoint stored in kdLatest variable.
//
// KdLatestURL is a wrapper around DefaultConfig.KdLatestURL.
func KdLatestURL(env string) (string, error) {
	return DefaultConfig.KdLatestURL(env)
}

// MustKdLatestURL returns endpoint stored in kdLatest variable. It panics in case of error.
func (c *Config) MustKdLatestURL(environment string) string {
	val, err := c.KdLatestURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustKdLatestURL returns endpoint stored in kdLatest variable.
//
// MustKdLatestURL is a wrapper around DefaultConfig.MustKdLatestURL.
func MustKdLatestURL(env string) string {
	return DefaultConfig.MustKdLatestURL(env)
}

// KlientLatestURL returns endpoint stored in klientLatest variable.
func (c *Config) KlientLatestURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.klientLatest", c.GetEnvironment(env))
}

// KlientLatestURL returns endpoint stored in klientLatest variable.
//
// KlientLatestURL is a wrapper around DefaultConfig.KlientLatestURL.
func KlientLatestURL(env string) (string, error) {
	return DefaultConfig.KlientLatestURL(env)
}

// MustKlientLatestURL returns endpoint stored in klientLatest variable. It panics in case of error.
func (c *Config) MustKlientLatestURL(environment string) string {
	val, err := c.KlientLatestURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustKlientLatestURL returns endpoint stored in klientLatest variable.
//
// MustKlientLatestURL is a wrapper around DefaultConfig.MustKlientLatestURL.
func MustKlientLatestURL(env string) string {
	return DefaultConfig.MustKlientLatestURL(env)
}

// KloudURL returns endpoint stored in kloud variable.
func (c *Config) KloudURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.kloud", c.GetEnvironment(env))
}

// KloudURL returns endpoint stored in kloud variable.
//
// KloudURL is a wrapper around DefaultConfig.KloudURL.
func KloudURL(env string) (string, error) {
	return DefaultConfig.KloudURL(env)
}

// MustKloudURL returns endpoint stored in kloud variable. It panics in case of error.
func (c *Config) MustKloudURL(environment string) string {
	val, err := c.KloudURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustKloudURL returns endpoint stored in kloud variable.
//
// MustKloudURL is a wrapper around DefaultConfig.MustKloudURL.
func MustKloudURL(env string) string {
	return DefaultConfig.MustKloudURL(env)
}

// KontrolURL returns endpoint stored in kontrol variable.
func (c *Config) KontrolURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.kontrol", c.GetEnvironment(env))
}

// KontrolURL returns endpoint stored in kontrol variable.
//
// KontrolURL is a wrapper around DefaultConfig.KontrolURL.
func KontrolURL(env string) (string, error) {
	return DefaultConfig.KontrolURL(env)
}

// MustKontrolURL returns endpoint stored in kontrol variable. It panics in case of error.
func (c *Config) MustKontrolURL(environment string) string {
	val, err := c.KontrolURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustKontrolURL returns endpoint stored in kontrol variable.
//
// MustKontrolURL is a wrapper around DefaultConfig.MustKontrolURL.
func MustKontrolURL(env string) string {
	return DefaultConfig.MustKontrolURL(env)
}

// TunnelServerURL returns endpoint stored in tunnelServer variable.
func (c *Config) TunnelServerURL(env string) (string, error) {
	return c.GetEndpoint("endpoints.tunnelServer", c.GetEnvironment(env))
}

// TunnelServerURL returns endpoint stored in tunnelServer variable.
//
// TunnelServerURL is a wrapper around DefaultConfig.TunnelServerURL.
func TunnelServerURL(env string) (string, error) {
	return DefaultConfig.TunnelServerURL(env)
}

// MustTunnelServerURL returns endpoint stored in tunnelServer variable. It panics in case of error.
func (c *Config) MustTunnelServerURL(environment string) string {
	val, err := c.TunnelServerURL(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// MustTunnelServerURL returns endpoint stored in tunnelServer variable.
//
// MustTunnelServerURL is a wrapper around DefaultConfig.MustTunnelServerURL.
func MustTunnelServerURL(env string) string {
	return DefaultConfig.MustTunnelServerURL(env)
}
