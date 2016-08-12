package bongo

import (
	"errors"

	"github.com/jinzhu/gorm"
)

var (
	RecordNotFound         = gorm.RecordNotFound
	IdIsNotSet             = errors.New("id is not set - empty")
	WrongParameter         = errors.New("wrong parameter list")
	CacherIsNotImplemented = errors.New("cacher is not implemented for given struct")
	ErrCacheIsNotEnabled   = errors.New("cache is not enabled")
)
