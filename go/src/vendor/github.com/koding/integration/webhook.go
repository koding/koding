package integration

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/koding/integration/services"
	"github.com/koding/logging"
)

type Handler struct {
	log logging.Logger
	sf  *services.Services
}

func NewHandler(l logging.Logger, sf *services.Services) *Handler {
	return &Handler{
		log: l,
		sf:  sf,
	}
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	token := req.URL.Query().Get("token")
	name := req.URL.Query().Get("name")

	if err := h.validate(name, token); err != nil {
		err = fmt.Errorf("could not validate request: %s", err)
		h.NewBadRequest(w, err)
		return
	}

	service, err := h.sf.Get(name)
	if err == services.ErrServiceNotFound {
		h.log.Error("Service not found: %s", name)
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	if err != nil {
		err = fmt.Errorf("could not get service: %s", err)
		h.NewBadRequest(w, err)
		return
	}

	service.ServeHTTP(w, req)
}

// Configure is used for configuring given services, like updating the url, selected events etc.
func (h *Handler) Configure(w http.ResponseWriter, req *http.Request) {
	serviceName := req.URL.Query().Get("name")
	// get service
	service, err := h.sf.Get(serviceName)
	if err != nil {
		h.NewBadRequest(w, err)
		return
	}

	// send configure request
	res, err := service.Configure(req)
	if err != nil {
		h.NewBadRequest(w, err)
		return
	}

	// return success response
	w.WriteHeader(http.StatusOK)
	bRes, err := json.Marshal(res)
	if err != nil {
		h.log.Error("Could not marshal response: %s", err)
		return
	}
	w.Write(bRes)
}

func (h *Handler) NewBadRequest(w http.ResponseWriter, err error) {
	h.log.Error("Bad request: %s", err)
	http.Error(w, err.Error(), http.StatusBadRequest)
}

func (h *Handler) validate(name, token string) error {
	if token == "" {
		return ErrTokenNotSet
	}

	if name == "" {
		return ErrNameNotSet
	}

	return nil
}
