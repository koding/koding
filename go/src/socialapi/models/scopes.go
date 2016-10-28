package models

import (
	"fmt"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

func RemoveTrollContent(i bongo.Modellable, disabled bool) bongo.Scope {
	return func(d *gorm.DB) *gorm.DB {
		if disabled {
			return d
		}

		if bongo.B.DB.NewScope(i).HasColumn("MetaBits") {
			d = d.Where("meta_bits <> ?", Troll)
		}

		return d
	}
}

func Paginated(limit, skip int) bongo.Scope {
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
func SortedByAddedAtASC(d *gorm.DB) *gorm.DB {
	return d.Order("added_at ASC")
}

func SortedByCreatedAt(d *gorm.DB) *gorm.DB {
	return d.Order("created_at DESC")
}

// TODO i am not sure about its place, maybe these must be moved to bongo
func ExcludeFields(pairs map[string]interface{}) bongo.Scope {
	return func(d *gorm.DB) *gorm.DB {
		for field, value := range pairs {

			q := fmt.Sprintf("%s <> ?", gorm.ToSnake(field))
			d = d.Where(q, value)
		}

		return d
	}
}

func Sort(pairs map[string]string) bongo.Scope {
	return func(d *gorm.DB) *gorm.DB {
		for field, value := range pairs {
			q := fmt.Sprintf("%s %s", gorm.ToSnake(field), value)
			d = d.Order(q)
		}

		return d
	}
}

func StartFrom(from time.Time) bongo.Scope {
	return func(d *gorm.DB) *gorm.DB {
		if !from.IsZero() {
			d = d.Where("created_at >= ?", from)
			d.Group("created_at")
		}

		return d
	}
}

func TillTo(to time.Time) bongo.Scope {
	return func(d *gorm.DB) *gorm.DB {
		if !to.IsZero() {
			d = d.Where("created_at <= ?", to)
		}

		return d
	}
}
