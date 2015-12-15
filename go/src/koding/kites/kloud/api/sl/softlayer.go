// Package ibm provides a client for IBM services:
//
//   - Softlayer (wip)
//
package sl

import (
	"bytes"
	"encoding/json"
	"fmt"
	"koding/kites/common"
	"os"
	"sort"

	"github.com/koding/logging"
	"github.com/maximilien/softlayer-go/client"
	"github.com/maximilien/softlayer-go/softlayer"
)

var defaultLogger = common.NewLogger("softlayer", false)

// workaround for softlayer-go API
var null = &bytes.Buffer{}

func init() {
	// To suppress softlayer-go debug printfs...
	os.Setenv("SL_GO_NON_VERBOSE", "YES")
}

// ProductionDatacenters describes Softlayer datacenters used in production.
//
// TODO(rjeczalik): This list is not complete nor confirmed, fix it.
var ProductionDatacenters = []string{
	"sjc01",
	"dal01",
}

// Options specifies configuration for the IBM services.
type Options struct {
	// SFClient custom Softlayer client to use.
	SLClient softlayer.Client

	// Datacenters where the results should be located.
	Datacenters []string

	// Log specifies custom logger to use.
	Log logging.Logger
}

// Softlayer is a wrapper client for softlayer-go client.
type Softlayer struct {
	// TODO(rjeczalik): eventually all softlayer.Client should be wrapped, so
	// the external softlayer-go client implementation is not tighly coupled
	// with our Softlayer provider.
	softlayer.Client

	account softlayer.SoftLayer_Account_Service
	guest   softlayer.SoftLayer_Virtual_Guest_Service
	block   softlayer.SoftLayer_Virtual_Guest_Block_Device_Template_Group_Service

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
	account, err := opts.SLClient.GetSoftLayer_Account_Service()
	if err != nil {
		panic("invalid softlayer.Client: " + err.Error())
	}
	guest, err := opts.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		panic("invalid softlayer.Client: " + err.Error())
	}
	block, err := opts.SLClient.GetSoftLayer_Virtual_Guest_Block_Device_Template_Group_Service()
	if err != nil {
		panic("invalid softlayer.Client: " + err.Error())
	}
	return &Softlayer{
		Client:  opts.SLClient,
		account: account,
		guest:   guest,
		block:   block,
		opts:    opts,
	}
}

// TemplatesByFilter fetches all templates and applies filter to the result set.
//
// If no templates are found that matches the filter, non-nil error is returned.
// If filter is nil, all templates are returned.
func (c *Softlayer) TemplatesByFilter(filter *Filter) (Templates, error) {
	path := fmt.Sprintf("%s/getBlockDeviceTemplateGroups.json", c.account.GetName())
	p, err := c.DoRawHttpRequestWithObjectMask(path, TemplateMasks, "GET", null)
	if err != nil {
		return nil, err
	}
	if err := checkAPIError(p); err != nil {
		return nil, err
	}

	var templates Templates
	if err := json.Unmarshal(p, &templates); err != nil {
		return nil, err
	}

	templates = templates.Filter(filter)

	if len(templates) == 0 {
		return nil, &NotFoundError{Filter: filter}
	}

	for _, template := range templates {
		template.decode()
	}

	sort.Sort(byCreateDateDesc(templates))

	return templates, nil
}

// TemplatesByFilter uses objectFilters to query Softlayer for templates.
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
	path := fmt.Sprintf("%s/getBlockDeviceTemplateGroups.json", c.account.GetName())
	p, err := c.DoRawHttpRequestWithObjectFilterAndObjectMask(
		path, TemplateMasks, filter.JSON(), "GET", null,
	)
	if err != nil {
		return nil, err
	}
	if err := checkAPIError(p); err != nil {
		return nil, err
	}

	var templates Templates
	if err := json.Unmarshal(p, &templates); err != nil {
		return nil, err
	}

	if len(templates) == 0 {
		return nil, &NotFoundError{Filter: filter}
	}

	for _, template := range templates {
		template.decode()
	}

	sort.Sort(byCreateDateDesc(templates))

	return templates, nil
}

func (c *Softlayer) log() logging.Logger {
	if c.opts.Log != nil {
		return c.opts.Log
	}
	return defaultLogger
}

func (c *Softlayer) datacenters() []string {
	if len(c.opts.Datacenters) != 0 {
		return c.opts.Datacenters
	}
	return ProductionDatacenters
}
