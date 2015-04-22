package digitalocean

import (
	"fmt"
	"strconv"
)

type DropletsResponse struct {
	Droplets []Droplet `json:"droplets"`
}

type DropletResponse struct {
	Droplet Droplet `json:"droplet"`
}

// Droplet is used to represent a retrieved Droplet. All properties
// are set as strings.
type Droplet struct {
	Id       int64                               `json:"id"`
	Name     string                              `json:"name"`
	Region   map[string]interface{}              `json:"region"`
	Image    map[string]interface{}              `json:"image"`
	SizeSlug string                              `json:"size_slug"`
	Locked   bool                                `json:"locked"`
	Status   string                              `json:"status"`
	Networks map[string][]map[string]interface{} `json:"networks"`
}

// Returns the slug for the region
func (d *Droplet) RegionSlug() string {
	if _, ok := d.Region["slug"]; ok {
		return d.Region["slug"].(string)
	}

	return ""
}

// Returns the slug for the region
func (d *Droplet) StringId() string {
	return strconv.FormatInt(d.Id, 10)
}

// Returns the string for Locked
func (d *Droplet) IsLocked() string {
	return strconv.FormatBool(d.Locked)
}

// Returns the slug for the image
func (d *Droplet) ImageSlug() string {
	if _, ok := d.Image["slug"]; ok {
		if attr, ok := d.Image["slug"].(string); ok {
			return attr
		}
	}

	return ""
}

func (d *Droplet) ImageId() string {
	if _, ok := d.Image["id"]; ok {
		if attr, ok := d.Image["id"].(float64); ok {
			return strconv.FormatFloat(attr, 'f', 0, 64)
		}
	}

	return ""
}

// Returns the ipv4 address
func (d *Droplet) IPV4Address(addressType string) string {
	if _, ok := d.Networks["v4"]; ok {
		for _, v := range d.Networks["v4"] {
			if v["type"].(string) == addressType {
				return v["ip_address"].(string)
			}
		}
	}
	return ""
}

// Returns the ipv6 adddress
func (d *Droplet) IPV6Address(addressType string) string {
	if _, ok := d.Networks["v6"]; ok {
		for _, v := range d.Networks["v6"] {
			if v["type"].(string) == addressType {
				return v["ip_address"].(string)
			}
		}
	}
	return ""
}

// Currently DO only has a network type per droplet,
// so we just takes ipv4s
func (d *Droplet) NetworkingType() string {
	if d.IPV4Address("private") != "" {
		return "private"
	} else {
		return "public"
	}
}

// CreateDroplet contains the request parameters to create a new
// droplet.
type CreateDroplet struct {
	Name              string   `json:"name,omitempty"`               // Name of the droplet
	Region            string   `json:"region,omitempty"`             // Slug of the region to create the droplet in
	Size              string   `json:"size,omitempty"`               // Slug of the size to use for the droplet
	Image             string   `json:"image,omitempty"`              // Slug of the image, if using a public image
	SSHKeys           []string `json:"ssh_keys,omitempty"`           // Array of SSH Key IDs that should be added
	Backups           bool     `json:"backups,omitempty"`            // true or false if backups are enabled
	IPV6              bool     `json:"ipv6,omitempty"`               // true or false if IPV6 is enabled
	PrivateNetworking bool     `json:"private_networking,omitempty"` // true or false if Private Networking is enabled
	UserData          string   `json:"user_data,omitempty"`          // metadata for the droplet
}

// CreateDroplet creates a droplet from the parameters specified and
// returns an error if it fails. If no error and an ID is returned,
// the Droplet was succesfully created.
func (c *Client) CreateDroplet(opts *CreateDroplet) (string, error) {
	req, err := c.NewRequest(opts, "POST", "/droplets")

	if err != nil {
		return "", err
	}

	resp, err := checkResp(c.Http.Do(req))

	if err != nil {
		return "", fmt.Errorf("Error creating droplet: %s", err)
	}

	droplet := new(DropletResponse)

	err = decodeBody(resp, &droplet)

	if err != nil {
		return "", fmt.Errorf("Error parsing droplet response: %s", err)
	}

	// The request was successful
	return droplet.Droplet.StringId(), nil
}

// DestroyDroplet destroys a droplet by the ID specified and
// returns an error if it fails. If no error is returned,
// the Droplet was succesfully destroyed.
func (c *Client) DestroyDroplet(id string) error {
	req, err := c.NewRequest(nil, "DELETE", fmt.Sprintf("/droplets/%s", id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error destroying droplet: %s", err)
	}

	// The request was successful
	return nil
}

// RetrieveDroplets gets the list of Droplets and an error. An error will
// be returned for failed requests with a nil slice.
func (c *Client) RetrieveDroplets() ([]Droplet, error) {
	req, err := c.NewRequest(map[string]string{}, "GET", "/droplets")

	if err != nil {
		return nil, err
	}

	resp, err := checkResp(c.Http.Do(req))
	if err != nil {
		return nil, fmt.Errorf("Error retrieving droplets: %s", err)
	}

	droplets := new(DropletsResponse)

	err = decodeBody(resp, droplets)

	if err != nil {
		return nil, fmt.Errorf("Error decoding droplet response: %s", err)
	}

	// The request was successful
	return droplets.Droplets, nil
}

// RetrieveDroplet gets  a droplet by the ID specified and
// returns a Droplet and an error. An error will be returned for failed
// requests with a nil Droplet.
func (c *Client) RetrieveDroplet(id string) (Droplet, error) {
	req, err := c.NewRequest(nil, "GET", fmt.Sprintf("/droplets/%s", id))

	if err != nil {
		return Droplet{}, err
	}

	resp, err := checkResp(c.Http.Do(req))
	if err != nil {
		return Droplet{}, fmt.Errorf("Error retrieving droplet: %s", err)
	}

	droplet := new(DropletResponse)

	err = decodeBody(resp, droplet)

	if err != nil {
		return Droplet{}, fmt.Errorf("Error decoding droplet response: %s", err)
	}

	// The request was successful
	return droplet.Droplet, nil
}

// Action sends the specified action to the droplet. An error
// is retunred, and is nil if successful
func (c *Client) Action(id string, action map[string]interface{}) error {
	req, err := c.NewRequest(action, "POST", fmt.Sprintf("/droplets/%s/actions", id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))
	if err != nil {
		return fmt.Errorf("Error processing droplet action: %s", err)
	}

	// The request was successful
	return nil
}

// Resizes a droplet to the size slug specified
func (c *Client) Resize(id string, size string) error {
	return c.Action(id, map[string]interface{}{
		"type": "resize",
		"size": size,
	})
}

// Renames a droplet to the name specified
func (c *Client) Rename(id string, name string) error {
	return c.Action(id, map[string]interface{}{
		"type": "rename",
		"name": name,
	})
}

// Enables IPV6 on the droplet
func (c *Client) EnableIPV6s(id string) error {
	return c.Action(id, map[string]interface{}{
		"type": "enable_ipv6",
	})
}

// Enables private networking on the droplet
func (c *Client) EnablePrivateNetworking(id string) error {
	return c.Action(id, map[string]interface{}{
		"type": "enable_private_networking",
	})
}

// Resizes a droplet to the size slug specified
func (c *Client) PowerOff(id string) error {
	return c.Action(id, map[string]interface{}{
		"type": "power_off",
	})
}

// Resizes a droplet to the size slug specified
func (c *Client) PowerOn(id string) error {
	return c.Action(id, map[string]interface{}{
		"type": "power_on",
	})
}
