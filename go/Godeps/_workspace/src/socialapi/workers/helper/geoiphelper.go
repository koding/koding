package helper

import (
	"socialapi/config"

	"github.com/oschwald/geoip2-golang"
)

var reader *geoip2.Reader

func MustGetGeoIPDB() *geoip2.Reader {
	if reader == nil {
		panic("GeoIpDB is nil")
	}

	return reader
}

func ReadGeoIPDB(c *config.Config) (*geoip2.Reader, error) {
	mmdb, err := geoip2.Open(c.Geoipdbpath + "/GeoLite2-City.mmdb")
	if err != nil {
		return nil, err
	}

	reader = mmdb

	return reader, nil
}
