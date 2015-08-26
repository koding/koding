package vagrantkite

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
			"vagrantkite_build": resourceVagrantKiteBuild(),
		},
	}
}
