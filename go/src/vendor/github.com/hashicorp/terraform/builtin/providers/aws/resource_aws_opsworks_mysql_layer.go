package aws

import (
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsOpsworksMysqlLayer() *schema.Resource {
	layerType := &opsworksLayerType{
		TypeName:         "db-master",
		DefaultLayerName: "MySQL",

		Attributes: map[string]*opsworksLayerTypeAttribute{
			"root_password": &opsworksLayerTypeAttribute{
				AttrName:  "MysqlRootPassword",
				Type:      schema.TypeString,
				WriteOnly: true,
			},
			"root_password_on_all_instances": &opsworksLayerTypeAttribute{
				AttrName: "MysqlRootPasswordUbiquitous",
				Type:     schema.TypeBool,
				Default:  true,
			},
		},
	}

	return layerType.SchemaResource()
}
