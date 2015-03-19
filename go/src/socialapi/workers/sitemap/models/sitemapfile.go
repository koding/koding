package models

import (
	"encoding/xml"
	"errors"
	"time"

	"github.com/koding/bongo"
)

var ErrNotSet = errors.New("name is not set")

type SitemapFile struct {
	Id int64

	// unique file name
	Name string `sql:"NOT NULL"`

	// file content
	Blob []byte

	// creation date of the file
	CreatedAt time.Time

	// last modification date of the file
	UpdatedAt time.Time

	isStatic bool
}

func (f *SitemapFile) ByName(name string) error {
	if name == "" {
		return ErrNotSet
	}

	selector := map[string]interface{}{
		"name": name,
	}
	q := bongo.NewQS(selector)

	return f.One(q)
}

func (f *SitemapFile) FetchAll() ([]SitemapFile, error) {
	files := make([]SitemapFile, 0)

	err := bongo.B.DB.Table(f.BongoName()).Select("name, updated_at").Find(&files).Error
	if err != nil {
		return files, err
	}

	return files, nil
}

func (f *SitemapFile) UnmarshalBlob() (*ItemSet, error) {
	set := NewItemSet()

	return set, xml.Unmarshal(f.Blob, set)
}

func (f *SitemapFile) Purge() error {
	return bongo.B.Purge(f)
}
