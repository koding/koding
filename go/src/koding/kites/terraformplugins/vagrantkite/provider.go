package vagrantkite

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

// Provider
func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		ResourcesMap: map[string]*schema.Resource{
			"vagnratkite_build": resourceVagrantKiteBuild(),
		},

		// we dont need ConfigureFunc
		// ConfigureFunc: providerConfigure,
	}
}
