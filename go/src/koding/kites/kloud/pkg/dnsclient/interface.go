package dnsclient

// Record represents a single record for a given domain
type Record struct {
	Name string
	Type string
	IP   string
	TTL  int
}

// Client is responsible of managing DNS records
type Client interface {
	// Upsert updates or creates a new domain record with the given name to the
	// new IP
	Upsert(name, newIP string) error

	// Delete deletes the given domain name.
	Delete(name string) error

	// Rename renames the given old domain name with the new domain name. To
	// change the IP, use the Upsert command.
	Rename(oldName, newName string) error

	// Get returns a domain record for the given domain name
	Get(name string) (*Record, error)

	// HostedZone returns the top level domain on which the domains are going
	// to be handled. Such as dev.koding.io or koding.io
	HostedZone() string

	// Validate validates if the given domain name is valid
	Validate(domainName, username string) error
}
