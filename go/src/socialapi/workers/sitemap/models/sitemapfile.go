package models

import (
	"errors"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var ErrNotSet = errors.New("name not set")

type SitemapFile struct {
	Id int64
	// unique file name
	Name string `sql:"NOT NULL"`

	// creation date of the file
	CreatedAt time.Time

	// last modification date of the file
	UpdatedAt time.Time
}

func (f SitemapFile) GetId() int64 {
	return f.Id
}

func (f SitemapFile) TableName() string {
	return "sitemap.file"
}

func (f *SitemapFile) Create() error {
	if f.Name == "" {
		return ErrNotSet
	}

	return bongo.B.Create(f)
}

func (f *SitemapFile) ByName(name string) error {
	selector := map[string]interface{}{
		"name": name,
	}
	q := bongo.NewQS(selector)

	return bongo.B.One(f, f, q)
}

func (f *SitemapFile) Upsert(name string) error {
	err := f.ByName(name)
	if err == gorm.RecordNotFound {
		return f.Create()
	}

	if err != nil {
		return err
	}

	return f.Update()
}

func (f *SitemapFile) Update() error {
	return bongo.B.Update(f)
}

func (f *SitemapFile) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(f, data, q)
}

func (f *SitemapFile) Fetch() error {
	return bongo.B.Fetch(f)
}
