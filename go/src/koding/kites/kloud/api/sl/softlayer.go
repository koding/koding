// Package ibm provides a client for IBM services:
//
//   - Softlayer (wip)
//
package sl

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"sort"

	"github.com/koding/logging"
	"github.com/maximilien/softlayer-go/client"
	"github.com/maximilien/softlayer-go/softlayer"
)

// TODO(rjeczalik): For now client side *ByFilter functions are preferred over
// server-side ones (X*ByFilter) due to weird and apparently worse performance
// of the latter. In the long run we would want to use server-side ones,
// as the client-side filtering does not scale.

var (
	// workaround for softlayer-go API
	nullBuf = &bytes.Buffer{}

	// ProductionDatacenters describes Softlayer datacenters used in production.
	//
	// TODO(rjeczalik): This list is not complete nor confirmed, fix it.
	ProductionDatacenters = []string{
		"sjc01",
		"dal01",
	}
)

// Options specifies configuration for the IBM services.
type Options struct {
	// SFClient custom Softlayer client to use.
	SLClient softlayer.Client

	// Datacenters where the results should be located.
	Datacenters []string

	// Log specifies custom logger to use.
	Log logging.Logger
}

func init() {
	// To suppress softlayer-go debug printfs...
	os.Setenv("SL_GO_NON_VERBOSE", "YES")
}

// Softlayer is a wrapper client for softlayer-go client.
type Softlayer struct {
	// TODO(rjeczalik): eventually all softlayer.Client methods should be
	// wrapped, so the external softlayer-go client implementation
	// is not tighly coupled with our Softlayer provider.
	softlayer.Client

	account softlayer.SoftLayer_Account_Service
	guest   softlayer.SoftLayer_Virtual_Guest_Service
	block   softlayer.SoftLayer_Virtual_Guest_Block_Device_Template_Group_Service
	sshkey  softlayer.SoftLayer_Security_Ssh_Key_Service

	opts *Options
}

// NewSoftlayer creates new Softlayer client for the given credentials.
func NewSoftlayer(username, apiKey string) (*Softlayer, error) {
	client := client.NewSoftLayerClient(username, apiKey)
	client.HTTPClient = NewClient()
	opts := &Options{
		SLClient: client,
	}
	return NewSoftlayerWithOptions(opts)
}

// NewSoftlayerWithOptions creates new Softlayer client for the given options.
func NewSoftlayerWithOptions(opts *Options) (*Softlayer, error) {
	account, err := opts.SLClient.GetSoftLayer_Account_Service()
	if err != nil {
		return nil, errors.New("invalid softlayer.Client: " + err.Error())
	}
	guest, err := opts.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return nil, errors.New("invalid softlayer.Client: " + err.Error())
	}
	block, err := opts.SLClient.GetSoftLayer_Virtual_Guest_Block_Device_Template_Group_Service()
	if err != nil {
		return nil, errors.New("invalid softlayer.Client: " + err.Error())
	}
	sshkey, err := opts.SLClient.GetSoftLayer_Security_Ssh_Key_Service()
	if err != nil {
		return nil, errors.New("invalid softlayer.Client: " + err.Error())
	}
	return &Softlayer{
		Client:  opts.SLClient,
		account: account,
		guest:   guest,
		block:   block,
		sshkey:  sshkey,
		opts:    opts,
	}, nil
}

// KeysByFilter fetches all keys and performs client-side filtering using the
// given filter.
//
// If no templates are found that matches the filter, non-nil error is returned.
// If filter is nil, all templates are returned.
func (c *Softlayer) KeysByFilter(filter *Filter) (Keys, error) {
	path := fmt.Sprintf("%s/getSshKeys.json", c.account.GetName())
	p, err := c.DoRawHttpRequestWithObjectMask(path, keyMask, "GET", nullBuf)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var keys Keys
	if err := json.Unmarshal(p, &keys); err != nil {
		return nil, err
	}

	for _, key := range keys {
		key.decode()
	}

	keys = keys.Filter(filter)

	if len(keys) == 0 {
		return nil, newNotFoundError("SshKey", fmt.Errorf("filter=%v", filter))
	}

	sort.Sort(byCreateDateKey(keys))

	return keys, nil
}

// XKeysByFilter queries for keys, which are filtered on the server side with
// the given filter.
//
// If no templates are found that matches the filter, non-nil error is returned.
// If filter is nil, all templates are returned.
func (c *Softlayer) XKeysByFilter(filter *Filter) (Keys, error) {
	objFilter := map[string]interface{}{
		"sshKeys": filter.Object(),
	}
	p, err := json.Marshal(objFilter)
	if err != nil {
		return nil, err
	}
	path := fmt.Sprintf("%s/getSshKeys.json", c.account.GetName())
	p, err = c.DoRawHttpRequestWithObjectFilterAndObjectMask(
		path, keyMask, string(p), "GET", nullBuf,
	)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var keys Keys
	if err := json.Unmarshal(p, &keys); err != nil {
		return nil, err
	}

	for _, key := range keys {
		key.decode()
	}

	keys = keys.Filter(filter)

	if len(keys) == 0 {
		return nil, newNotFoundError("SshKey", fmt.Errorf("filter=%v", filter))
	}

	sort.Sort(byCreateDateKey(keys))

	return keys, nil
}

// CreateKey creates new SSH key on the Softlayer endpoint.
//
// If the operation is successful it returns the key with its ID and
// CreateDate properties populated by the Softlayer endpoint.
func (c *Softlayer) CreateKey(key *Key) (*Key, error) {
	if err := key.encode(); err != nil {
		return nil, fmt.Errorf("failed to encode key %+v: %s", key, err)
	}

	req := map[string]interface{}{
		"parameters": []interface{}{key},
	}
	p, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	path := fmt.Sprintf("%s/createObject.json", c.sshkey.GetName())
	p, err = c.DoRawHttpRequest(path, "POST", bytes.NewBuffer(p))
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var createdKey Key
	if err := json.Unmarshal(p, &createdKey); err != nil {
		return nil, err
	}

	createdKey.decode()
	return &createdKey, nil
}

// DeleteKey deletes SSH key given by the id.
func (c *Softlayer) DeleteKey(id int) error {
	path := fmt.Sprintf("%s/%d", c.sshkey.GetName(), id)
	p, err := c.DoRawHttpRequest(path, "DELETE", nullBuf)
	if err != nil {
		return err
	}
	if err := checkError(p); err != nil {
		return err
	}

	var ok bool
	if err := json.Unmarshal(p, &ok); err != nil {
		return err
	}

	if !ok {
		return fmt.Errorf("failed to delete SSH key id=%d", id)
	}

	return nil
}

// TemplatesByFilter fetches all templates and performs client-side filtering
// using the given filter.
//
// If no templates are found that matches the filter, non-nil error is returned.
// If filter is nil, all templates are returned.
func (c *Softlayer) TemplatesByFilter(filter *Filter) (Templates, error) {
	path := fmt.Sprintf("%s/getBlockDeviceTemplateGroups.json", c.account.GetName())
	p, err := c.DoRawHttpRequestWithObjectMask(path, templateMask, "GET", nullBuf)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var templates Templates
	if err := json.Unmarshal(p, &templates); err != nil {
		return nil, err
	}

	for _, template := range templates {
		template.decode()
	}

	templates = templates.Filter(filter)

	if len(templates) == 0 {
		return nil, newNotFoundError("Template", fmt.Errorf("filter=%v", filter))
	}

	sort.Sort(byCreateDateDesc(templates))

	return templates, nil
}

// TemplatesByFilter queries for templates, which are filtered on the server
// side with the given filter.
//
// If no templates are found that matches the filter, non-nil error is returned.
// If filter is nil, all templates are returned.
//
// NOTE(rjeczalik): Fetching all templates in test environment (18 items)
// takes ~1s, fetching templates with Datacenter filter on using this method
// takes 5s - seems like Softlayer is not performant if filters on so-called
// "relational properties" are used.
//
// However I'm leaving the code, as an example how to use object filters.
// More on the topic:
//
//   https://sldn.softlayer.com/article/Object-Filters
//   https://github.com/softlayer/softlayer-python/blob/50c60bd/SoftLayer/utils.py#L71-L113
//
func (c *Softlayer) XTemplatesByFilter(filter *Filter) (Templates, error) {
	objFilter := map[string]interface{}{
		"blockDeviceTemplateGroups": filter.Object(),
	}
	p, err := json.Marshal(objFilter)
	if err != nil {
		return nil, err
	}
	path := fmt.Sprintf("%s/getBlockDeviceTemplateGroups.json", c.account.GetName())
	p, err = c.DoRawHttpRequestWithObjectFilterAndObjectMask(
		path, templateMask, string(p), "GET", nullBuf,
	)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var templates Templates
	if err := json.Unmarshal(p, &templates); err != nil {
		return nil, err
	}

	if len(templates) == 0 {
		return nil, newNotFoundError("Template", fmt.Errorf("filter=%v", filter))
	}

	for _, template := range templates {
		template.decode()
	}

	sort.Sort(byCreateDateDesc(templates))

	return templates, nil
}

// DatacentersByFilter
func (c *Softlayer) DatacentersByFilter(filter *Filter) (Datacenters, error) {
	const path = "SoftLayer_Location_Datacenter/getDatacenters.json"
	p, err := c.DoRawHttpRequestWithObjectMask(path, datacenterMask, "GET", nullBuf)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var datacenters Datacenters
	if err := json.Unmarshal(p, &datacenters); err != nil {
		return nil, err
	}

	datacenters = datacenters.Filter(filter)

	if len(datacenters) == 0 {
		return nil, newNotFoundError("Datacenter", fmt.Errorf("filter=%v", filter))
	}

	return datacenters, nil
}

// XDatacentersByFilter
func (c *Softlayer) XDatacentersByFilter(filter *Filter) (Datacenters, error) {
	const path = "SoftLayer_Location_Datacenter/getDatacenters.json"
	objFilter := map[string]interface{}{
		"locations": filter.Object(),
	}
	p, err := json.Marshal(objFilter)
	if err != nil {
		return nil, err
	}

	p, err = c.DoRawHttpRequestWithObjectFilterAndObjectMask(
		path, datacenterMask, string(p), "GET", nullBuf,
	)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}

	var datacenters Datacenters
	if err := json.Unmarshal(p, &datacenters); err != nil {
		return nil, err
	}

	datacenters = datacenters.Filter(filter)

	if len(datacenters) == 0 {
		return nil, newNotFoundError("Datacenter", fmt.Errorf("filter=%v", filter))
	}

	return datacenters, nil
}

// DeleteInstance requests a VM termination given by the id.
func (c *Softlayer) DeleteInstance(id int) error {
	path := fmt.Sprintf("%s/%d", c.guest.GetName(), id)
	p, err := c.DoRawHttpRequest(path, "DELETE", nullBuf)
	if err != nil {
		return err
	}

	if err := checkError(p); err != nil {
		return err
	}

	var ok bool
	if err := json.Unmarshal(p, &ok); err != nil {
		return err
	}

	if !ok {
		return fmt.Errorf("failed to delete instance id=%d", id)
	}

	return nil
}
