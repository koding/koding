package openstack

import (
	"encoding/json"
	"errors"
	"net/url"
	"strings"

	"github.com/racker/perigee"
	"github.com/rackspace/gophercloud"
)

type ItemNotFound struct {
	ItemNotFound struct {
		Message string `json:"message"`
		Code    int    `json:"code"`
	} `json:"itemNotFound"`
}

type Servers []gophercloud.Server

// Filter returns a new modified server list which only contains droplets with
// the given name.
func (s Servers) Filter(name string) Servers {
	filtered := make(Servers, 0)

	for _, server := range s {
		if strings.Contains(server.Name, name) {
			filtered = append(filtered, server)
		}
	}

	return filtered
}

// Servers returns all available servers based for this openstack client
func (o *Openstack) Servers() (Servers, error) {
	return o.Client.ListServersLinksOnly()
}

func (o *Openstack) ServersByFilter(filter url.Values) (Servers, error) {
	return o.Client.ListServersByFilter(filter)
}

// Server returns a server instance from the server ID
func (o *Openstack) Server() (*gophercloud.Server, error) {
	if o.Id() == "" {
		return nil, errors.New("Server id is empty")
	}

	s, err := o.Client.ServerById(o.Id())
	if err == nil {
		return s, nil
	}

	unexpErr, ok := err.(*perigee.UnexpectedResponseCodeError)
	if !ok {
		return nil, err
	}

	notFound := ItemNotFound{}
	if jsonErr := json.Unmarshal(unexpErr.Body, &notFound); jsonErr != nil {
		return nil, err // send our initial error, we couldn't make it
	}

	if strings.Contains(notFound.ItemNotFound.Message, "Instance could not be found") {
		return nil, ErrServerNotFound
	}

	return nil, err
}
