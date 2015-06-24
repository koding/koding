package schema

import (
	"errors"
	"fmt"
	"sort"

	"github.com/hashicorp/terraform/terraform"
)

// Provider represents a resource provider in Terraform, and properly
// implements all of the ResourceProvider API.
//
// By defining a schema for the configuration of the provider, the
// map of supporting resources, and a configuration function, the schema
// framework takes over and handles all the provider operations for you.
//
// After defining the provider structure, it is unlikely that you'll require any
// of the methods on Provider itself.
type Provider struct {
	// Schema is the schema for the configuration of this provider. If this
	// provider has no configuration, this can be omitted.
	//
	// The keys of this map are the configuration keys, and the value is
	// the schema describing the value of the configuration.
	Schema map[string]*Schema

	// ResourcesMap is the list of available resources that this provider
	// can manage, along with their Resource structure defining their
	// own schemas and CRUD operations.
	//
	// Provider automatically handles routing operations such as Apply,
	// Diff, etc. to the proper resource.
	ResourcesMap map[string]*Resource

	// ConfigureFunc is a function for configuring the provider. If the
	// provider doesn't need to be configured, this can be omitted.
	//
	// See the ConfigureFunc documentation for more information.
	ConfigureFunc ConfigureFunc

	meta interface{}
}

// ConfigureFunc is the function used to configure a Provider.
//
// The interface{} value returned by this function is stored and passed into
// the subsequent resources as the meta parameter. This return value is
// usually used to pass along a configured API client, a configuration
// structure, etc.
type ConfigureFunc func(*ResourceData) (interface{}, error)

// InternalValidate should be called to validate the structure
// of the provider.
//
// This should be called in a unit test for any provider to verify
// before release that a provider is properly configured for use with
// this library.
func (p *Provider) InternalValidate() error {
	if p == nil {
		return errors.New("provider is nil")
	}

	sm := schemaMap(p.Schema)
	if err := sm.InternalValidate(sm); err != nil {
		return err
	}

	for k, r := range p.ResourcesMap {
		if err := r.InternalValidate(nil); err != nil {
			return fmt.Errorf("%s: %s", k, err)
		}
	}

	return nil
}

// Meta returns the metadata associated with this provider that was
// returned by the Configure call. It will be nil until Configure is called.
func (p *Provider) Meta() interface{} {
	return p.meta
}

// SetMeta can be used to forcefully set the Meta object of the provider.
// Note that if Configure is called the return value will override anything
// set here.
func (p *Provider) SetMeta(v interface{}) {
	p.meta = v
}

// Input implementation of terraform.ResourceProvider interface.
func (p *Provider) Input(
	input terraform.UIInput,
	c *terraform.ResourceConfig) (*terraform.ResourceConfig, error) {
	return schemaMap(p.Schema).Input(input, c)
}

// Validate implementation of terraform.ResourceProvider interface.
func (p *Provider) Validate(c *terraform.ResourceConfig) ([]string, []error) {
	return schemaMap(p.Schema).Validate(c)
}

// ValidateResource implementation of terraform.ResourceProvider interface.
func (p *Provider) ValidateResource(
	t string, c *terraform.ResourceConfig) ([]string, []error) {
	r, ok := p.ResourcesMap[t]
	if !ok {
		return nil, []error{fmt.Errorf(
			"Provider doesn't support resource: %s", t)}
	}

	return r.Validate(c)
}

// Configure implementation of terraform.ResourceProvider interface.
func (p *Provider) Configure(c *terraform.ResourceConfig) error {
	// No configuration
	if p.ConfigureFunc == nil {
		return nil
	}

	sm := schemaMap(p.Schema)

	// Get a ResourceData for this configuration. To do this, we actually
	// generate an intermediary "diff" although that is never exposed.
	diff, err := sm.Diff(nil, c)
	if err != nil {
		return err
	}

	data, err := sm.Data(nil, diff)
	if err != nil {
		return err
	}

	meta, err := p.ConfigureFunc(data)
	if err != nil {
		return err
	}

	p.meta = meta
	return nil
}

// Apply implementation of terraform.ResourceProvider interface.
func (p *Provider) Apply(
	info *terraform.InstanceInfo,
	s *terraform.InstanceState,
	d *terraform.InstanceDiff) (*terraform.InstanceState, error) {
	r, ok := p.ResourcesMap[info.Type]
	if !ok {
		return nil, fmt.Errorf("unknown resource type: %s", info.Type)
	}

	return r.Apply(s, d, p.meta)
}

// Diff implementation of terraform.ResourceProvider interface.
func (p *Provider) Diff(
	info *terraform.InstanceInfo,
	s *terraform.InstanceState,
	c *terraform.ResourceConfig) (*terraform.InstanceDiff, error) {
	r, ok := p.ResourcesMap[info.Type]
	if !ok {
		return nil, fmt.Errorf("unknown resource type: %s", info.Type)
	}

	return r.Diff(s, c)
}

// Refresh implementation of terraform.ResourceProvider interface.
func (p *Provider) Refresh(
	info *terraform.InstanceInfo,
	s *terraform.InstanceState) (*terraform.InstanceState, error) {
	r, ok := p.ResourcesMap[info.Type]
	if !ok {
		return nil, fmt.Errorf("unknown resource type: %s", info.Type)
	}

	return r.Refresh(s, p.meta)
}

// Resources implementation of terraform.ResourceProvider interface.
func (p *Provider) Resources() []terraform.ResourceType {
	keys := make([]string, 0, len(p.ResourcesMap))
	for k, _ := range p.ResourcesMap {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	result := make([]terraform.ResourceType, 0, len(keys))
	for _, k := range keys {
		result = append(result, terraform.ResourceType{
			Name: k,
		})
	}

	return result
}
