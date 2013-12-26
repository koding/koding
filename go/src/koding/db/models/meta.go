package models

import (
	"time"
)

type Meta struct {
	ModifiedAt time.Time `bson:"modifiedAt"`
	CreatedAt  time.Time `bson:"createdAt"`
	Likes      int       `bson:"likes"`
}
