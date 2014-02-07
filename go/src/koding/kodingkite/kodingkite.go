package kodingkite

import (
	"fmt"
	"koding/kite"
	"koding/tools/config"
	"net/url"
	"strconv"
)

type Options kite.Options

// New returns a new kite instance based on for the given Koding configurations
func New(config *config.Config, options Options) *kite.Kite {
	kontrolPort := strconv.Itoa(config.NewKontrol.Port)
	kontrolHost := config.NewKontrol.Host
	kontrolURL := &url.URL{
		Scheme: "ws",
		Host:   fmt.Sprintf("%s:%s", kontrolHost, kontrolPort),
		Path:   "/dnode",
	}

	// Update config
	options.Environment = config.Environment
	options.Region = config.Regions.SJ
	options.KontrolURL = kontrolURL

	o := kite.Options(options)
	return kite.New(&o)
}
