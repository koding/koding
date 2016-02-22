package dnsclient

import (
	"net"
	"strings"
)

// Records is a wrapper type for a slice of records that supports filtering.
type Records []*Record

// ByName filters the records than contain the  given name part.
func (r Records) ByName(name string) (res Records) {
	if name == "" {
		return r
	}
	name = strings.ToLower(name)
	for _, record := range r {
		if strings.ToLower(record.Name) == name {
			res = append(res, record)
		}
	}
	return res
}

// ByType filters the records by the given type.
func (r Records) ByType(typ string) (res Records) {
	if typ == "" {
		return r
	}
	typ = strings.ToLower(typ)
	for _, record := range r {
		if strings.ToLower(record.Type) == typ {
			res = append(res, record)
		}
	}
	return res
}

// ByValue filters the records by the given value.
func (r Records) ByValue(value string) (res Records) {
	if value == "" {
		return r
	}
	for _, record := range r {
		if record.IP == value {
			res = append(res, record)
		}
	}
	return res
}

// User filters out hosted zone records.
func (r Records) User() (res Records) {
	for _, record := range r {
		typ := strings.ToLower(record.Type)

		// filter out hosted zone records
		if typ != "soa" && typ != "ns" {
			res = append(res, record)
		}
	}
	return res
}

// Filter filters the records by the given filter f.
func (r Records) Filter(f *Record) Records {
	if f == nil {
		return r
	}
	return r.ByValue(f.IP).ByType(f.Type).ByName(f.Name)
}

// ParseRecord tries to detect DNS record type required for
// the given address.
func ParseRecord(domain, address string) *Record {
	host, _, err := net.SplitHostPort(address)
	if err == nil {
		address = host
	}

	if net.ParseIP(address) != nil {
		return &Record{
			Name: domain,
			Type: "A",
			IP:   address,
			TTL:  30,
		}
	}

	return &Record{
		Name: domain,
		Type: "CNAME",
		IP:   address,
		TTL:  30,
	}
}
