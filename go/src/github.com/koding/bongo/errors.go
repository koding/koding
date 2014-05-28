package bongo

import (
	"errors"

	"github.com/jinzhu/gorm"
)

var (
	RecordNotFound = gorm.RecordNotFound
	IdIsNotSet     = errors.New("Id is not set - empty")
)
