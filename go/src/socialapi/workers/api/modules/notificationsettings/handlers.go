package notificationsettings

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  Create,
			Name:     "notification-settings-create",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/notificationsettings",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Get,
			Name:     "notification-settings-get",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}/notificationsettings",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Update,
			Name:     "notification-settings-update",
			Type:     handler.PostRequest,
			Endpoint: "/notificationsettings/{id}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Delete,
			Name:     "notification-settings-delete",
			Type:     handler.DeleteRequest,
			Endpoint: "/notificationsettings/{id}",
		},
	)
}
