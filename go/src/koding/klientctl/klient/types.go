package klient

import "koding/klient/client"

// FilesEvent is an embedded PublishRequest struct with the data used for the
// "openFiles" event.
type FilesEvent struct {
	client.PublishRequest

	Files []string `json:"files"`
}
