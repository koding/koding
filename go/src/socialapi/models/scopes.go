package models

import (
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

func RemoveTrollContent(i bongo.Modellable, disabled bool) func(d *gorm.DB) *gorm.DB {
	return func(d *gorm.DB) *gorm.DB {
		if disabled {
			return d
		}

		if bongo.B.DB.NewScope(i).HasColumn("MetaBits") {
			d = d.Where("meta_bits = ?", 0)
		}

		return d
	}
}

func Paginated(limit, skip int) func(d *gorm.DB) *gorm.DB {
	return func(d *gorm.DB) *gorm.DB {
		// add skip
		if skip > 0 {
			d = d.Offset(skip)
		}

		// add limit
		if limit > 0 {
			d = d.Limit(limit)
		}

		return d
	}
}

func SortedByAddedAt(d *gorm.DB) *gorm.DB {
	return d.Order("added_at DESC")
}

func SortedByCreatedAt(d *gorm.DB) *gorm.DB {
	return d.Order("created_at DESC")
}
