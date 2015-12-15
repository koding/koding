package sl

import (
	"encoding/json"
	"errors"
)

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
func (f *Filter) JSON() (string, error) {
	if f == nil {
		return "", nil
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
		return "", nil
	}
	m = map[string]interface{}{
		"blockDeviceTemplateGroups": m,
	}
	p, err := json.Marshal(m)
	if err != nil {
		return "", errors.New("error marshaling filter: " + err.Error())
	}
	return string(p), nil
}
