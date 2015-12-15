package sl

import "encoding/json"

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
}

// JSON returns the objectFilter JSON representation of the filter.
func (f *Filter) JSON() string {
	type Option struct {
		Name  string      `json:"name,omitempty"`
		Value interface{} `json:"value,omitempty"`
	}
	if f == nil {
		return ""
	}
	m := make(map[string]interface{})
	if f.Name != "" {
		m["name"] = map[string]interface{}{
			"operation": f.Name,
		}
	}
	if f.ID != 0 {
		m["id"] = map[string]interface{}{
			"operation": f.ID,
		}
	}
	if f.Datacenter != "" && !f.Children {
		m["datacenters"] = map[string]interface{}{
			"name": map[string]interface{}{
				"operation": f.Datacenter,
			},
		}
	}
	// TODO(rjeczalik): research how to support tags
	if len(m) == 0 {
		return ""
	}
	m = map[string]interface{}{
		"blockDeviceTemplateGroups": m,
	}
	p, err := json.Marshal(m)
	if err != nil {
		panic("error marshaling filter: " + err.Error())
	}
	return string(p)
}
