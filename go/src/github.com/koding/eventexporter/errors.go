package eventexporter

import "errors"

var (
	ErrorSegmentIOUsernameEmpty = errors.New("username is empty")
	ErrorSegmentIOEventEmpty    = errors.New("event is empty")
)
