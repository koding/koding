package sl

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
)

var errNotFound = errors.New("not found")

// Resource defines an operations that need to be supported by
// a concrete resource type.
type Resource interface {
	Err() error
}

// ResourceDecoder provides a mean to optionally perform additional decoding
// of a resource after unmarshalling and before sorting.
type ResorceDecoder interface {
	Decode()
}

// ResourceSorter provides common sorter interface. If a resource implements it,
// it will be sorted before filtering.
type ResourceSorter interface {
	sort.Interface
}

// ResourceFilter provides common filterin interface. If a resource implements it,
// it will be filtered before calling Err() on it.
type ResourceFilter interface {
	Filter(*Filter)
}

// TagRequest is a generic POST request that tags Softlayer resources.
//
// It overwrites all tags. The TODO is to make it not.
type TagRequest struct {
	Name    string // name of the resource
	Service string // API path to resource's service
	ID      int    // resource's ID
	Tags    Tags   // tags to be set for a resource
}

func (c *Softlayer) tag(req *TagRequest) error {
	body := map[string]interface{}{
		"parameters": []interface{}{req.Tags.Ref()},
	}
	p, err := json.Marshal(body)
	if err != nil {
		return err
	}

	path := fmt.Sprintf("%s/%d/setTags.json", req.Service, req.ID)
	p, _, err = c.DoRawHttpRequest(path, "POST", bytes.NewBuffer(p))
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
		return fmt.Errorf("failed setting tags for %s id=%d", req.Name, req.ID)
	}

	return nil
}

// RequestResource is a generic GET request for Softlayer resources.
type ResourceRequest struct {
	Name       string   // name of the resource
	Path       string   // API path to fetch the resource
	Filter     *Filter  // filter to apply on the resource
	FilterName string   // API filter name for server-side filtering
	ObjectMask []string // field list to fetch for the resource
	Resource   Resource // resource value
}

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

	// Perform soring if the resource supports it.
	if sorter, ok := req.Resource.(ResourceSorter); ok {
		sort.Sort(sorter)
	}

	// Filter the resource if it's supported
	if req.Filter != nil {
		if filter, ok := req.Resource.(ResourceFilter); ok {
			filter.Filter(req.Filter)
		}
	}

	if err := req.Resource.Err(); err != nil {
		if err == errNotFound {
			return newNotFoundError(req.Name, fmt.Errorf("filter=%v", req.Filter))
		}

		return err
	}

	return nil
}

func (c *Softlayer) clientGet(req *ResourceRequest) ([]byte, error) {
	p, _, err := c.DoRawHttpRequestWithObjectMask(
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
	p, _, err = c.DoRawHttpRequestWithObjectFilterAndObjectMask(
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
