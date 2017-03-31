package models

// GroupData holds a group's private info.
type GroupData struct {
	ID   string `json:"_id"`
	Slug string `json:"slug"`
	Data *Data  `bson:"data,omitempty" json:"data,omitempty"`
}
