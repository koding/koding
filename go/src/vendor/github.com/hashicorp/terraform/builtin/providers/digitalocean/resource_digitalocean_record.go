package digitalocean

import (
	"fmt"
	"log"
	"strconv"
	"strings"

	"github.com/digitalocean/godo"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceDigitalOceanRecord() *schema.Resource {
	return &schema.Resource{
		Create: resourceDigitalOceanRecordCreate,
		Read:   resourceDigitalOceanRecordRead,
		Update: resourceDigitalOceanRecordUpdate,
		Delete: resourceDigitalOceanRecordDelete,

		Schema: map[string]*schema.Schema{
			"type": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"domain": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"port": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"priority": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"weight": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"value": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"fqdn": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func resourceDigitalOceanRecordCreate(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*godo.Client)

	newRecord := godo.DomainRecordEditRequest{
		Type: d.Get("type").(string),
		Name: d.Get("name").(string),
		Data: d.Get("value").(string),
	}

	var err error
	if priority := d.Get("priority").(string); priority != "" {
		newRecord.Priority, err = strconv.Atoi(priority)
		if err != nil {
			return fmt.Errorf("Failed to parse priority as an integer: %v", err)
		}
	}
	if port := d.Get("port").(string); port != "" {
		newRecord.Port, err = strconv.Atoi(port)
		if err != nil {
			return fmt.Errorf("Failed to parse port as an integer: %v", err)
		}
	}
	if weight := d.Get("weight").(string); weight != "" {
		newRecord.Weight, err = strconv.Atoi(weight)
		if err != nil {
			return fmt.Errorf("Failed to parse weight as an integer: %v", err)
		}
	}

	log.Printf("[DEBUG] record create configuration: %#v", newRecord)
	rec, _, err := client.Domains.CreateRecord(d.Get("domain").(string), &newRecord)
	if err != nil {
		return fmt.Errorf("Failed to create record: %s", err)
	}

	d.SetId(strconv.Itoa(rec.ID))
	log.Printf("[INFO] Record ID: %s", d.Id())

	return resourceDigitalOceanRecordRead(d, meta)
}

func resourceDigitalOceanRecordRead(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*godo.Client)
	domain := d.Get("domain").(string)
	id, err := strconv.Atoi(d.Id())
	if err != nil {
		return fmt.Errorf("invalid record ID: %v", err)
	}

	rec, resp, err := client.Domains.Record(domain, id)
	if err != nil {
		// If the record is somehow already destroyed, mark as
		// successfully gone
		if resp.StatusCode == 404 {
			d.SetId("")
			return nil
		}

		return err
	}

	// Update response data for records with domain value
	if t := rec.Type; t == "CNAME" || t == "MX" || t == "NS" || t == "SRV" {
		// Append dot to response if resource value is absolute
		if value := d.Get("value").(string); strings.HasSuffix(value, ".") {
			rec.Data += "."
			// If resource value ends with current domain, make response data absolute
			if strings.HasSuffix(value, domain+".") {
				rec.Data += domain + "."
			}
		}
	}

	d.Set("name", rec.Name)
	d.Set("type", rec.Type)
	d.Set("value", rec.Data)
	d.Set("weight", strconv.Itoa(rec.Weight))
	d.Set("priority", strconv.Itoa(rec.Priority))
	d.Set("port", strconv.Itoa(rec.Port))

	en := constructFqdn(rec.Name, d.Get("domain").(string))
	log.Printf("[DEBUG] Constructed FQDN: %s", en)
	d.Set("fqdn", en)

	return nil
}

func resourceDigitalOceanRecordUpdate(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*godo.Client)

	domain := d.Get("domain").(string)
	id, err := strconv.Atoi(d.Id())
	if err != nil {
		return fmt.Errorf("invalid record ID: %v", err)
	}

	var editRecord godo.DomainRecordEditRequest
	if v, ok := d.GetOk("name"); ok {
		editRecord.Name = v.(string)
	}

	log.Printf("[DEBUG] record update configuration: %#v", editRecord)
	_, _, err = client.Domains.EditRecord(domain, id, &editRecord)
	if err != nil {
		return fmt.Errorf("Failed to update record: %s", err)
	}

	return resourceDigitalOceanRecordRead(d, meta)
}

func resourceDigitalOceanRecordDelete(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*godo.Client)

	domain := d.Get("domain").(string)
	id, err := strconv.Atoi(d.Id())
	if err != nil {
		return fmt.Errorf("invalid record ID: %v", err)
	}

	log.Printf("[INFO] Deleting record: %s, %d", domain, id)

	resp, delErr := client.Domains.DeleteRecord(domain, id)
	if delErr != nil {
		// If the record is somehow already destroyed, mark as
		// successfully gone
		if resp.StatusCode == 404 {
			return nil
		}

		return fmt.Errorf("Error deleting record: %s", delErr)
	}

	return nil
}

func constructFqdn(name, domain string) string {
	rn := strings.ToLower(strings.TrimSuffix(name, "."))
	domain = strings.TrimSuffix(domain, ".")
	if !strings.HasSuffix(rn, domain) {
		rn = strings.Join([]string{name, domain}, ".")
	}
	return rn
}
