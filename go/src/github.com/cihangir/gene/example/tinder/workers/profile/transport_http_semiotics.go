package profile

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
	EndpointNameCreate = "create"
	EndpointNameDelete = "delete"
	EndpointNameMarkAs = "markas"
	EndpointNameOne    = "one"
	EndpointNameUpdate = "update"
)

type semiotic struct {
	Name               string
	Method             string
	Route              string
	ServerEndpointFunc func(svc ProfileService) endpoint.Endpoint
	DecodeRequestFunc  httptransport.DecodeRequestFunc
	EncodeRequestFunc  httptransport.EncodeRequestFunc
	EncodeResponseFunc httptransport.EncodeResponseFunc
	DecodeResponseFunc httptransport.DecodeResponseFunc
}

var semiotics = map[string]semiotic{

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

	EndpointNameDelete: semiotic{
		Name:               EndpointNameDelete,
		Method:             "POST",
		ServerEndpointFunc: makeDeleteEndpoint,
		Route:              "/" + EndpointNameDelete,
		DecodeRequestFunc:  decodeDeleteRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeDeleteResponse,
	},

	EndpointNameMarkAs: semiotic{
		Name:               EndpointNameMarkAs,
		Method:             "POST",
		ServerEndpointFunc: makeMarkAsEndpoint,
		Route:              "/" + EndpointNameMarkAs,
		DecodeRequestFunc:  decodeMarkAsRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeMarkAsResponse,
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

func decodeCreateRequest(r *http.Request) (interface{}, error) {
	var req models.Profile
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeDeleteRequest(r *http.Request) (interface{}, error) {
	var req int64
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeMarkAsRequest(r *http.Request) (interface{}, error) {
	var req models.MarkAsRequest
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
	var req models.Profile
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

// Decode Response functions

func decodeCreateResponse(r *http.Response) (interface{}, error) {
	var res models.Profile
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeDeleteResponse(r *http.Response) (interface{}, error) {
	var res int64
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeMarkAsResponse(r *http.Response) (interface{}, error) {
	var res models.MarkAsRequest
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
	var res models.Profile
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

func makeCreateEndpoint(svc ProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*models.Profile)
		return svc.Create(ctx, req)
	}
}

func makeDeleteEndpoint(svc ProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*int64)
		return svc.Delete(ctx, req)
	}
}

func makeMarkAsEndpoint(svc ProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*models.MarkAsRequest)
		return svc.MarkAs(ctx, req)
	}
}

func makeOneEndpoint(svc ProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*int64)
		return svc.One(ctx, req)
	}
}

func makeUpdateEndpoint(svc ProfileService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*models.Profile)
		return svc.Update(ctx, req)
	}
}
