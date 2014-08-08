package models

type EventContent struct {
	// event content
	ActivityTime string
	ActorContact UserContact
	Action       string
	Size         int
	Slug         string
	Uri          string
	ObjectType   string
	Group        GroupContent
	Message      string
}
