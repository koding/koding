package ns1

import (
	"github.com/hashicorp/terraform/helper/schema"

	ns1 "gopkg.in/ns1/ns1-go.v2/rest"
	"gopkg.in/ns1/ns1-go.v2/rest/model/data"
)

func dataSourceResource() *schema.Resource {
	return &schema.Resource{
		Schema: map[string]*schema.Schema{
			"id": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"sourcetype": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"config": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
			},
		},
		Create: DataSourceCreate,
		Read:   DataSourceRead,
		Update: DataSourceUpdate,
		Delete: DataSourceDelete,
	}
}

func dataSourceToResourceData(d *schema.ResourceData, s *data.Source) {
	d.SetId(s.ID)
	d.Set("name", s.Name)
	d.Set("sourcetype", s.Type)
	d.Set("config", s.Config)
}

// DataSourceCreate creates an ns1 datasource
func DataSourceCreate(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*ns1.Client)
	s := data.NewSource(d.Get("name").(string), d.Get("sourcetype").(string))
	s.Config = d.Get("config").(map[string]interface{})
	if _, err := client.DataSources.Create(s); err != nil {
		return err
	}
	dataSourceToResourceData(d, s)
	return nil
}

// DataSourceRead fetches info for the given datasource from ns1
func DataSourceRead(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*ns1.Client)
	s, _, err := client.DataSources.Get(d.Id())
	if err != nil {
		return err
	}
	dataSourceToResourceData(d, s)
	return nil
}

// DataSourceDelete deteltes the given datasource from ns1
func DataSourceDelete(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*ns1.Client)
	_, err := client.DataSources.Delete(d.Id())
	d.SetId("")
	return err
}

// DataSourceUpdate updates the datasource with given parameters
func DataSourceUpdate(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*ns1.Client)
	s := data.NewSource(d.Get("name").(string), d.Get("sourcetype").(string))
	s.ID = d.Id()
	if _, err := client.DataSources.Update(s); err != nil {
		return err
	}
	dataSourceToResourceData(d, s)
	return nil
}
