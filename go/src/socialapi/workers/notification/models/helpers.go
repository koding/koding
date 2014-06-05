package models

import (
	"time"
)

// TODO copied from api/models
func ZeroDate() time.Time {
	return time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)
}
