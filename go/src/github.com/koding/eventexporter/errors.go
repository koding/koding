package eventexporter

import "errors"

var (
	// SegmentIO
	ErrSegmentIOUsernameEmpty = errors.New("username is empty")
	ErrSegmentIOEmailEmpty    = errors.New("email is empty")
	ErrSegmentIOEventEmpty    = errors.New("event is empty")
	ErrSendgridBodyEmpty      = errors.New("email body is empty")

	//Druid
	ErrDruidAddressNotSet = errors.New("DruidExporter address is not set")
)
