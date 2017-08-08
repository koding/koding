package test

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func Provider() terraform.ResourceProvider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			// Optional attribute to label a particular instance for a test
			// that has multiple instances of this provider, so that they
			// can be distinguished using the test_provider_label data source.
			"label": {
				Type:     schema.TypeString,
				Optional: true,
			},
		},
		ResourcesMap: map[string]*schema.Resource{
			"test_resource":         testResource(),
			"test_resource_gh12183": testResourceGH12183(),
		},
		DataSourcesMap: map[string]*schema.Resource{
			"test_data_source":    testDataSource(),
			"test_provider_label": providerLabelDataSource(),
		},
		ConfigureFunc: providerConfigure,
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	return d.Get("label"), nil
}
