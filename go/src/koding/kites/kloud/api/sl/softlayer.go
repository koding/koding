// Package ibm provides a client for IBM services:
//
//   - Softlayer (wip)
//
package sl

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"

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
	softlayer.HttpClient

	opts *Options
}

// NewSoftlayer creates new Softlayer client for the given credentials.
func NewSoftlayer(username, apiKey string) *Softlayer {
	client := client.NewSoftLayerClient(username, apiKey)
	opts := &Options{
		SLClient: client,
	}
	return NewSoftlayerWithOptions(opts)
}

// NewSoftlayerWithOptions creates new Softlayer client for the given options.
func NewSoftlayerWithOptions(opts *Options) *Softlayer {
	s := &Softlayer{
		Client:     opts.SLClient,
		HttpClient: opts.SLClient.GetHttpClient(),
		opts:       opts,
	}

	if c, ok := s.HttpClient.(*client.HttpClient); ok {
		c.HTTPClient = NewClient()
	}

	return s
}

// KeysByFilter fetches all keys and performs client-side filtering using the
// given filter.
//
// If no keys are found that matches the filter, non-nil error is returned.
// If filter is nil, all keys are returned.
func (c *Softlayer) KeysByFilter(filter *Filter) (Keys, error) {
	req := &ResourceRequest{
		Name:       "SshKey",
		Path:       "SoftLayer_Account/getSshKeys.json",
		Filter:     filter,
		ObjectMask: keyMask,
		Resource:   &Keys{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Keys), nil
}

// XKeysByFilter queries for keys, which are filtered on the server side with
// the given filter.
//
// If no keys are found that matches the filter, non-nil error is returned.
// If filter is nil, all keys are returned.
func (c *Softlayer) XKeysByFilter(filter *Filter) (Keys, error) {
	req := &ResourceRequest{
		Name:       "SshKey",
		Path:       "SoftLayer_Account/getSshKeys.json",
		Filter:     filter,
		FilterName: "sshKeys",
		ObjectMask: keyMask,
		Resource:   &Keys{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Keys), nil
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

	const path = "SoftLayer_Security_Ssh_Key/createObject.json"
	p, _, err = c.DoRawHttpRequest(path, "POST", bytes.NewBuffer(p))
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
	path := fmt.Sprintf("SoftLayer_Security_Ssh_Key/%d", id)
	p, _, err := c.DoRawHttpRequest(path, "DELETE", nullBuf)
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
	req := &ResourceRequest{
		Name:       "Template",
		Path:       "SoftLayer_Account/getBlockDeviceTemplateGroups.json",
		Filter:     filter,
		ObjectMask: templateMask,
		Resource:   &Templates{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Templates), nil
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
	req := &ResourceRequest{
		Name:       "Template",
		Path:       "SoftLayer_Account/getBlockDeviceTemplateGroups.json",
		Filter:     filter,
		FilterName: "blockDeviceTemplateGroups",
		ObjectMask: templateMask,
		Resource:   &Templates{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Templates), nil
}

// DatacentersByFilter fetches all keys and performs client-side filtering
// using the given filter.
//
// If no datacenters are found that matches the filter, non-nil error is
// returned.
// If filter is nil, all datacenters are returned.
func (c *Softlayer) DatacentersByFilter(filter *Filter) (Datacenters, error) {
	req := &ResourceRequest{
		Name:       "Datacenter",
		Path:       "SoftLayer_Location_Datacenter/getDatacenters.json",
		Filter:     filter,
		ObjectMask: datacenterMask,
		Resource:   &Datacenters{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Datacenters), nil
}

// XDatacentersByFilter queries for keys, which are filtered on the server side
// with the given filter.
//
// If no datacenters are found that matches the filter, non-nil error is
// returned.
// If filter is nil, all datacenters are returned.
func (c *Softlayer) XDatacentersByFilter(filter *Filter) (Datacenters, error) {
	req := &ResourceRequest{
		Name:       "Datacenter",
		Path:       "SoftLayer_Location_Datacenter/getDatacenters.json",
		Filter:     filter,
		FilterName: "locations",
		ObjectMask: datacenterMask,
		Resource:   &Datacenters{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Datacenters), nil
}

// InstancesByFilter fetches all instances and performs client-side filtering
// using the given filter.
//
// If no instances are found that matches the filter, non-nil error is returned.
// If filter is nil, all instances are returned.
func (c *Softlayer) InstancesByFilter(filter *Filter) (Instances, error) {
	req := &ResourceRequest{
		Name:       "Instance",
		Path:       "SoftLayer_Account/getVirtualGuests.json",
		Filter:     filter,
		ObjectMask: instanceMask,
		Resource:   &Instances{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Instances), nil
}

// XInstancesByFilter queries for keys, which are filtered on the server side
// with the given filter.
//
// If no instances are found that matches the filter, non-nil error is returned.
// If filter is nil, all instances are returned.
func (c *Softlayer) XInstancesByFilter(filter *Filter) (Instances, error) {
	req := &ResourceRequest{
		Name:       "Instance",
		Path:       "SoftLayer_Account/getVirtualGuests.json",
		Filter:     filter,
		FilterName: "virtualGuests",
		ObjectMask: instanceMask,
		Resource:   &Instances{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*Instances), nil
}

// InstanceEntriesByFilter fetches all instance entries and performs client-side
// filtering using the given filter.
//
// If no instance entries are found that matches the filter, non-nil error
// is returned.
// If filter is nil, all instance entries are returned.
func (c *Softlayer) InstanceEntriesByFilter(filter *Filter) (InstanceEntries, error) {
	req := &ResourceRequest{
		Name:       "Instance",
		Path:       "SoftLayer_Account/getVirtualGuests.json",
		Filter:     filter,
		ObjectMask: instanceEntryMask,
		Resource:   &InstanceEntries{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*InstanceEntries), nil
}

// InstancesInVlan fetches all instances within the VLAN given by the id.
func (c *Softlayer) InstancesInVlan(id int) (Instances, error) {
	req := &ResourceRequest{
		Name:       "Vlan",
		Path:       fmt.Sprintf("SoftLayer_Network_Vlan/%d/getObject.json", id),
		ObjectMask: vlanInstancesMask,
		Resource:   &VLAN{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}

	i := Instances(req.Resource.(*VLAN).Instances)
	if err := i.Err(); err != nil {
		return nil, err
	}
	return i, nil
}

// XInstancesByFilter queries for keys, which are filtered on the server side
// with the given filter.
//
// If no instances are found that matches the filter, non-nil error is returned.
// If filter is nil, all instances are returned.
func (c *Softlayer) XInstanceEntriesByFilter(filter *Filter) (InstanceEntries, error) {
	req := &ResourceRequest{
		Name:       "Instance",
		Path:       "SoftLayer_Account/getVirtualGuests.json",
		Filter:     filter,
		FilterName: "virtualGuests",
		ObjectMask: instanceEntryMask,
		Resource:   &InstanceEntries{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*InstanceEntries), nil
}

// VlansByFilter fetches all vlans and performs client-side filtering
// using the given filter.
//
// If no vlans are found that matches the filter, non-nil error is returned.
// If filter is nil, all vlans are returned.
func (c *Softlayer) VlansByFilter(filter *Filter) (VLANs, error) {
	req := &ResourceRequest{
		Name:       "Vlan",
		Path:       "SoftLayer_Account/getNetworkVlans.json",
		Filter:     filter,
		ObjectMask: vlanMask,
		Resource:   &VLANs{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*VLANs), nil
}

// XVlansByFilter queries for vlans, which are filtered on the server side
// with the given filter.
//
// If no vlans are found that matches the filter, non-nil error is returned.
// If filter is nil, all vlans are returned.
func (c *Softlayer) XVlansByFilter(filter *Filter) (VLANs, error) {
	req := &ResourceRequest{
		Name:       "Vlan",
		Path:       "SoftLayer_Account/getNetworkVlans.json",
		Filter:     filter,
		FilterName: "networkVlans",
		ObjectMask: vlanMask,
		Resource:   &VLANs{},
	}
	if err := c.get(req); err != nil {
		return nil, err
	}
	return *req.Resource.(*VLANs), nil
}

// InstanceSetTags sets tags of the instance specified by the id to the provided
// value. All old tags will get overwritten.
func (c *Softlayer) InstanceSetTags(id int, tags Tags) error {
	req := &TagRequest{
		Name:    "Instance",
		Service: "SoftLayer_Virtual_Guest",
		ID:      id,
		Tags:    tags,
	}
	return c.tag(req)
}

// VlanSetTags sets tags of the vlan specified by the id to the provided
// value. All old tags will get overwritten.
func (c *Softlayer) VlanSetTags(id int, tags Tags) error {
	req := &TagRequest{
		Name:    "Vlan",
		Service: "SoftLayer_Network_Vlan",
		ID:      id,
		Tags:    tags,
	}
	return c.tag(req)
}

// DeleteInstance requests a VM termination given by the id.
func (c *Softlayer) DeleteInstance(id int) error {
	path := fmt.Sprintf("SoftLayer_Virtual_Guest/%d", id)
	p, _, err := c.DoRawHttpRequest(path, "DELETE", nullBuf)
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
