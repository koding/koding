package facebookprofile

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"

	"github.com/cihangir/gene/example/tinder/models"
	"github.com/go-kit/kit/endpoint"
	httptransport "github.com/go-kit/kit/transport/http"
	"golang.org/x/net/context"
)

const (
	EndpointNameByIDs  = "byids"
	EndpointNameCreate = "create"
	EndpointNameOne    = "one"
	EndpointNameUpdate = "update"
)

type semiotic struct {
	Name               string
	Method             string
	Route              string
	ServerEndpointFunc func(svc FacebookProfileService) endpoint.Endpoint
	DecodeRequestFunc  httptransport.DecodeRequestFunc
	EncodeRequestFunc  httptransport.EncodeRequestFunc
	EncodeResponseFunc httptransport.EncodeResponseFunc
	DecodeResponseFunc httptransport.DecodeResponseFunc
}

var semiotics = map[string]semiotic{

	EndpointNameByIDs: semiotic{
		Name:               EndpointNameByIDs,
		Method:             "POST",
		ServerEndpointFunc: makeByIDsEndpoint,
		Route:              "/" + EndpointNameByIDs,
		DecodeRequestFunc:  decodeByIDsRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeByIDsResponse,
	},

	EndpointNameCreate: semiotic{
		Name:               EndpointNameCreate,
		Method:             "POST",
		ServerEndpointFunc: makeCreateEndpoint,
		Route:              "/" + EndpointNameCreate,
		DecodeRequestFunc:  decodeCreateRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeCreateResponse,
	},

	EndpointNameOne: semiotic{
		Name:               EndpointNameOne,
		Method:             "POST",
		ServerEndpointFunc: makeOneEndpoint,
		Route:              "/" + EndpointNameOne,
		DecodeRequestFunc:  decodeOneRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeOneResponse,
	},

	EndpointNameUpdate: semiotic{
		Name:               EndpointNameUpdate,
		Method:             "POST",
		ServerEndpointFunc: makeUpdateEndpoint,
		Route:              "/" + EndpointNameUpdate,
		DecodeRequestFunc:  decodeUpdateRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeUpdateResponse,
	},
}

// Decode Request functions

func decodeByIDsRequest(r *http.Request) (interface{}, error) {
	var req []string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeCreateRequest(r *http.Request) (interface{}, error) {
	var req models.FacebookProfile
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeOneRequest(r *http.Request) (interface{}, error) {
	var req int64
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeUpdateRequest(r *http.Request) (interface{}, error) {
	var req models.FacebookProfile
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

// Decode Response functions

func decodeByIDsResponse(r *http.Response) (interface{}, error) {
	var res []string
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeCreateResponse(r *http.Response) (interface{}, error) {
	var res models.FacebookProfile
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeOneResponse(r *http.Response) (interface{}, error) {
	var res int64
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeUpdateResponse(r *http.Response) (interface{}, error) {
	var res models.FacebookProfile
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

// Encode request function

func encodeRequest(r *http.Request, request interface{}) error {
	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(request); err != nil {
		return err
	}
	r.Body = ioutil.NopCloser(&buf)
	return nil
}

// Encode response function

func encodeResponse(rw http.ResponseWriter, response interface{}) error {
	return json.NewEncoder(rw).Encode(response)
}

// Endpoint functions

func makeByIDsEndpoint(svc FacebookProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*[]string)
		return svc.ByIDs(ctx, req)
	}
}

func makeCreateEndpoint(svc FacebookProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*models.FacebookProfile)
		return svc.Create(ctx, req)
	}
}

func makeOneEndpoint(svc FacebookProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*int64)
		return svc.One(ctx, req)
	}
}

func makeUpdateEndpoint(svc FacebookProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*models.FacebookProfile)
		return svc.Update(ctx, req)
	}
}
