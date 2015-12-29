package sl

import (
	"encoding/json"
	"fmt"
	"sort"
)

// Resource
type Resource interface {
	sort.Interface
	Filter(*Filter)
}

// ResourceDecoder
type ResorceDecoder interface {
	Decode()
}

// RequestResource
type ResourceRequest struct {
	Name       string   // name of the resource
	Path       string   // API path to fetch the resource
	Filter     *Filter  // filter to apply on the resource
	FilterName string   // API filter name for server-side filtering
	ObjectMask []string // field list to fetch for the resource
	Resource   Resource // resource value
}

// fetch
func (c *Softlayer) get(req *ResourceRequest) error {
	var p []byte
	var err error
	if req.Filter != nil && req.FilterName != "" {
		p, err = c.serverGet(req)
	} else {
		p, err = c.clientGet(req)
	}
	if err != nil {
		return err
	}
	if err := json.Unmarshal(p, req.Resource); err != nil {
		return err
	}
	// Perform additional decoding of the resource, if supported.
	if decoder, ok := req.Resource.(ResorceDecoder); ok {
		decoder.Decode()
	}
	// Filter the resource.
	if req.Filter != nil {
		req.Resource.Filter(req.Filter)
	}
	if req.Resource.Len() == 0 {
		return newNotFoundError(req.Name, fmt.Errorf("filter=%v", req.Filter))
	}
	// Sort the resource.
	sort.Sort(req.Resource)
	return nil
}

func (c *Softlayer) clientGet(req *ResourceRequest) ([]byte, error) {
	p, err := c.DoRawHttpRequestWithObjectMask(
		req.Path, req.ObjectMask, "GET", nullBuf,
	)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}
	return p, nil
}

func (c *Softlayer) serverGet(req *ResourceRequest) ([]byte, error) {
	objFilter := map[string]interface{}{
		req.FilterName: req.Filter.Object(),
	}
	p, err := json.Marshal(objFilter)
	if err != nil {
		return nil, err
	}
	p, err = c.DoRawHttpRequestWithObjectFilterAndObjectMask(
		req.Path, req.ObjectMask, string(p), "GET", nullBuf,
	)
	if err != nil {
		return nil, err
	}
	if err := checkError(p); err != nil {
		return nil, err
	}
	return p, nil
}
