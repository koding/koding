// Package vagrant provides communication layer between terraform and remote
// klient
package vagrant

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

// Provider returns a terraform.ResourceProvider.
func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		// we dont require a schema right now
		// Schema: map[string]*schema.Schema{},

		// we dont require configuration per run
		// ConfigureFunc: providerConfigure

		ResourcesMap: map[string]*schema.Resource{
			// vagrant_instance builds a new vagrant machine on the remote
			// klient
			"vagrant_instance": resourceVagrantBuild(),
		},
	}
}
