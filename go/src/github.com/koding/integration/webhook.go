package integration

import (
	"encoding/json"
	"net/http"

	"github.com/koding/integration/services"
	"github.com/koding/logging"
)

type Handler struct {
	log  logging.Logger
	sf   *services.ServiceFactory
	conf *services.ServiceConfig
}

func NewHandler(l logging.Logger, conf *services.ServiceConfig) *Handler {
	return &Handler{
		log:  l,
		sf:   services.NewServiceFactory(),
		conf: conf,
	}
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	token := req.URL.Query().Get("token")
	name := req.URL.Query().Get("name")

	if err := h.validate(name, token); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	service, err := h.sf.Create(name, h.conf)
	if err == services.ErrServiceNotFound {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	service.ServeHTTP(w, req)
}

// Configure is used for configuring given services, like updating the url, selected events etc.
func (h *Handler) Configure(w http.ResponseWriter, req *http.Request) {
	serviceName := req.URL.Query().Get("name")
	// get service
	service, err := h.sf.Create(serviceName, h.conf)
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
