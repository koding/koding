package api

import (
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

const (
	UserInfo      = "user-info"
	MachineGet    = "machine-get"
	MachineStatus = "machine-status"
)

func AddHandlers(m *mux.Mux, config *config.Config) {
	// These handlers's full path is gonna be changed
	m.AddHandler(
		handler.Request{
			Handler:  Info,
			Name:     UserInfo,
			Type:     handler.GetRequest,
			Endpoint: "/user/info",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetMachine,
			Name:     MachineGet,
			Type:     handler.GetRequest,
			Endpoint: "/machine/{id}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetMachineStatus,
			Name:     MachineStatus,
			Type:     handler.GetRequest,
			Endpoint: "/machine/{id}",
		},
	)

}
