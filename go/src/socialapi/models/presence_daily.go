package models

import "time"

// PresenceDaily holds presence info on day granuality
type PresenceDaily struct {
	// Id unique identifier of the channel
	Id int64 `json:"id,string"`

	// AccountId holds the active users info
	AccountId int64 `json:"accountId,string"         sql:"NOT NULL"`

	// Name of the group
	GroupName string `json:"name" sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creation date of the record
	CreatedAt time.Time `json:"createdAt"            sql:"NOT NULL"`

	// IsProcessed did we processed the record?
	IsProcessed bool `json:"IsDeleted"`
}
