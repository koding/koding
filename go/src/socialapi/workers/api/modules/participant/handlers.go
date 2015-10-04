package participant

import (
	"socialapi/models"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  List,
			Name:     "participant-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}/participants",
			Securer:  models.ParticipantReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AddMulti,
			Name:     "participant-multi-add",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/add",
			Securer:  models.ParticipantMultiSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  RemoveMulti,
			Name:     "participant-multi-remove",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/remove",
			Securer:  models.ParticipantMultiSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  BlockMulti,
			Name:     "participant-multi-block",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/block",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  UnblockMulti,
			Name:     "participant-multi-unblock",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/unblock",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  UpdatePresence,
			Name:     "participant-presence-update",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participant/{accountId}/presence",
			Securer:  models.ParticipantSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AcceptInvite,
			Name:     "participant-invitation-accept",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/invitation/accept",
			Securer:  models.ParticipantSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  RejectInvite,
			Name:     "participant-invitation-reject",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/invitation/reject",
			Securer:  models.ParticipantSecurer,
		},
	)
}
