package githubprovider

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

// Provider returns a terraform.ResourceProvider.
func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"userKey": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				DefaultFunc: schema.EnvDefaultFunc("GITHUB_USERKEY", nil),
				Description: "The token key for user operations.",
			},

			"organizationKey": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				DefaultFunc: schema.EnvDefaultFunc("GITHUB_ORGANIZATIONKEY", nil),
				Description: "The token key for organization operations.",
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"github_adduser": resourceGithubAddUser(),
		},

		ConfigureFunc: providerConfigure,
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	config := &Config{
		UserKey:         d.Get("userKey").(string),
		OrganizationKey: d.Get("organizationKey").(string),
	}

	return config.Clients()
}
