package bongo

import (
	"errors"

	"github.com/jinzhu/gorm"
)

var (
	RecordNotFound = gorm.RecordNotFound
	IdIsNotSet     = errors.New("id is not set - empty")
	WrongParameter = errors.New("wrong parameter list")
)
