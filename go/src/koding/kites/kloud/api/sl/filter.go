package sl

// Filter is used for querying Softlayer resources.
type Filter struct {
	// ID is the ID of the resource.
	ID int

	// Name is the name of the resource.
	Name string

	// Datacenter specifies where the resource is located or in what
	// datacenters the resource is available.
	Datacenter string

	// Tags specifies what tags the resource should have.
	Tags Tags

	// Children includes also children templates.
	//
	// By default only parent templates are returned - the ones having
	// ParentID equal to 0.
	Children bool

	// Label is the label of the resource.
	Label string

	// User is a user to which the resource is attached to. In most
	// cases it's a shorthand for Tags["user"].
	User string

	// Fingerprint is a fingerprint of the resource.
	Fingerprint string

	// Hostname of the instance.
	Hostname string
}

// op is a helper function that wraps given value with {"operation": value}.
func op(value interface{}) interface{} {
	return map[string]interface{}{
		"operation": value,
	}
}

// Object returns the objectFilter representation of the filter.
//
// TODO(rjeczalik): infer from JSON tags
func (f *Filter) Object() map[string]interface{} {
	if f == nil {
		return nil
	}
	m := make(map[string]interface{})
	if f.Name != "" {
		m["name"] = op(f.Name)
	}
	if f.ID != 0 {
		m["id"] = op(f.ID)
	}
	if f.Datacenter != "" && !f.Children {
		// If children are also to be collected, then it's not
		// possible to filter items with objectFilter - parent items
		// have "datacenters" field and children - "datacenter" one.
		// Filtering by one of them would remove the other group
		// from the result set.
		m["datacenters"] = map[string]interface{}{
			"name": op(f.Datacenter),
		}
	}
	if f.Label != "" {
		m["label"] = op(f.Label)
	}
	if f.Fingerprint != "" {
		m["fingerprint"] = op(f.Fingerprint)
	}
	if f.Hostname != "" {
		m["hostname"] = op(f.Hostname)
	}
	// TODO(rjeczalik): f.Tags - research how to support tags
	// TODO(rjeczalik): f.User - like above
	if len(m) == 0 {
		return nil
	}
	return m
}
