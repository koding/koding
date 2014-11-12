package models

import "time"

type Permission struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// name of the permission
	Name string `json:"name"`

	// admin, moderator, member, guest
	RoleConstant string `json:"roleConstant"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string"       sql:"NOT NULL"`

	// Status of the permission in the channel
	// Allowed/Disallowed
	StatusConstant string `json:"statusConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creation date of permission
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the permission
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
}
