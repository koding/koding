package machine

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"

	"socialapi/workers/kodingapi/models"
	"github.com/go-kit/kit/endpoint"
	httptransport "github.com/go-kit/kit/transport/http"
	"golang.org/x/net/context"
)

const (
	EndpointNameGetMachine       = "getmachine"
	EndpointNameGetMachineStatus = "getmachinestatus"
	EndpointNameListMachines     = "listmachines"
)

type semiotic struct {
	Name               string
	Method             string
	Route              string
	ServerEndpointFunc func(svc MachineService) endpoint.Endpoint
	DecodeRequestFunc  httptransport.DecodeRequestFunc
	EncodeRequestFunc  httptransport.EncodeRequestFunc
	EncodeResponseFunc httptransport.EncodeResponseFunc
	DecodeResponseFunc httptransport.DecodeResponseFunc
}

var semiotics = map[string]semiotic{

	EndpointNameGetMachine: semiotic{
		Name:               EndpointNameGetMachine,
		Method:             "POST",
		ServerEndpointFunc: makeGetMachineEndpoint,
		Route:              "/" + EndpointNameGetMachine,
		DecodeRequestFunc:  decodeGetMachineRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeGetMachineResponse,
	},

	EndpointNameGetMachineStatus: semiotic{
		Name:               EndpointNameGetMachineStatus,
		Method:             "POST",
		ServerEndpointFunc: makeGetMachineStatusEndpoint,
		Route:              "/" + EndpointNameGetMachineStatus,
		DecodeRequestFunc:  decodeGetMachineStatusRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeGetMachineStatusResponse,
	},

	EndpointNameListMachines: semiotic{
		Name:               EndpointNameListMachines,
		Method:             "POST",
		ServerEndpointFunc: makeListMachinesEndpoint,
		Route:              "/" + EndpointNameListMachines,
		DecodeRequestFunc:  decodeListMachinesRequest,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decodeListMachinesResponse,
	},
}

// Decode Request functions

func decodeGetMachineRequest(r *http.Request) (interface{}, error) {
	var req string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeGetMachineStatusRequest(r *http.Request) (interface{}, error) {
	var req string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

func decodeListMachinesRequest(r *http.Request) (interface{}, error) {
	var req string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}

// Decode Response functions

func decodeGetMachineResponse(r *http.Response) (interface{}, error) {
	var res models.Machine
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeGetMachineStatusResponse(r *http.Response) (interface{}, error) {
	var res models.Machine
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}

func decodeListMachinesResponse(r *http.Response) (interface{}, error) {
	var res []models.Machine
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

func makeGetMachineEndpoint(svc MachineService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*string)
		return svc.GetMachine(ctx, req)
	}
}

func makeGetMachineStatusEndpoint(svc MachineService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*string)
		return svc.GetMachineStatus(ctx, req)
	}
}

func makeListMachinesEndpoint(svc MachineService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*string)
		return svc.ListMachines(ctx, req)
	}
}
