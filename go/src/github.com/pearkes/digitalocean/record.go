package digitalocean

import (
	"fmt"
	"strconv"
)

type RecordResponse struct {
	Record Record `json:"domain_record"`
}

// Record is used to represent a retrieved Record. All properties
// are set as strings.
type Record struct {
	Id       int    `json:"id"`
	Type     string `json:"type"`
	Name     string `json:"name"`
	Data     string `json:"data"`
	Priority int    `json:"priority"`
	Port     int    `json:"port"`
	Weight   int    `json:"weight"`
}

func (r *Record) StringId() string {
	return strconv.Itoa(r.Id)
}

func (r *Record) StringPriority() string {
	return strconv.Itoa(r.Priority)
}

func (r *Record) StringPort() string {
	return strconv.Itoa(r.Port)
}

func (r *Record) StringWeight() string {
	return strconv.Itoa(r.Weight)
}

// CreateRecord contains the request parameters to create a new
// record.
type CreateRecord struct {
	Type     string
	Name     string
	Data     string
	Priority string
	Port     string
	Weight   string
}

// CreateRecord creates a record from the parameters specified and
// returns an error if it fails. If no error and the name is returned,
// the Record was succesfully created.
func (c *Client) CreateRecord(domain string, opts *CreateRecord) (string, error) {
	// Make the request parameters
	params := make(map[string]string)

	params["type"] = opts.Type

	if opts.Name != "" {
		params["name"] = opts.Name
	}

	if opts.Data != "" {
		params["data"] = opts.Data
	}

	if opts.Priority != "" {
		params["priority"] = opts.Priority
	}

	if opts.Port != "" {
		params["port"] = opts.Port
	}

	if opts.Weight != "" {
		params["weight"] = opts.Weight
	}

	req, err := c.NewRequest(params, "POST", fmt.Sprintf("/domains/%s/records", domain))
	if err != nil {
		return "", err
	}

	resp, err := checkResp(c.Http.Do(req))

	if err != nil {
		return "", fmt.Errorf("Error creating record: %s", err)
	}

	record := new(RecordResponse)

	err = decodeBody(resp, &record)

	if err != nil {
		return "", fmt.Errorf("Error parsing record response: %s", err)
	}

	// The request was successful
	return record.Record.StringId(), nil
}

// DestroyRecord destroys a record by the ID specified and
// returns an error if it fails. If no error is returned,
// the Record was succesfully destroyed.
func (c *Client) DestroyRecord(domain string, id string) error {
	req, err := c.NewRequest(map[string]string{}, "DELETE", fmt.Sprintf("/domains/%s/records/%s", domain, id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error destroying record: %s", err)
	}

	// The request was successful
	return nil
}

// UpdateRecord contains the request parameters to create a new
// record.
type UpdateRecord struct {
	Name string
}

// UpdateRecord destroys a record by the ID specified and
// returns an error if it fails. If no error is returned,
// the Record was succesfully updated.
func (c *Client) UpdateRecord(domain string, id string, opts *UpdateRecord) error {
	params := make(map[string]string)

	params["name"] = opts.Name

	req, err := c.NewRequest(params, "PUT", fmt.Sprintf("/domains/%s/records/%s", domain, id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error updating record: %s", err)
	}

	// The request was successful
	return nil
}

// RetrieveRecord gets  a record by the ID specified and
// returns a Record and an error. An error will be returned for failed
// requests with a nil Record.
func (c *Client) RetrieveRecord(domain string, id string) (Record, error) {
	req, err := c.NewRequest(map[string]string{}, "GET", fmt.Sprintf("/domains/%s/records/%s", domain, id))

	if err != nil {
		return Record{}, err
	}

	resp, err := checkResp(c.Http.Do(req))
	if err != nil {
		return Record{}, fmt.Errorf("Error destroying record: %s", err)
	}

	record := new(RecordResponse)

	err = decodeBody(resp, record)

	if err != nil {
		return Record{}, fmt.Errorf("Error decoding record response: %s", err)
	}

	// The request was successful
	return record.Record, nil
}
