package openstack

import "github.com/rackspace/gophercloud"

type Flavors []gophercloud.Flavor

func (f Flavors) Has(id string) bool {
	for _, flavor := range f {
		if flavor.Id == id {
			return true
		}
	}

	return false
}

// Image returns a single image based on the given image id, slug or id. It
// checks for each occurency and returns for the first match.
func (o *Openstack) Flavors() (Flavors, error) {
	return o.Client.ListFlavors()
}
