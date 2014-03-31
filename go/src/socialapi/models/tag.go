package models

import "time"

type Tag struct {
	Id        int64
	Slug      string
	CreatedAt time.Time
}
