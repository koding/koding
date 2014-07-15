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
}

func NewSitemapFile() *SitemapFile {
	return &SitemapFile{}
}

func (f SitemapFile) GetId() int64 {
	return f.Id
}

func (f SitemapFile) TableName() string {
	return "sitemap.file"
}

func (f *SitemapFile) BeforeCreate() error {
	if f.Name == "" {
		return ErrNotSet
	}

	return nil
}

func (f *SitemapFile) Create() error {
	return bongo.B.Create(f)
}

func (f *SitemapFile) One(q *bongo.Query) error {
	return bongo.B.One(f, f, q)
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

func (f *SitemapFile) Update() error {
	return bongo.B.Update(f)
}

func (f *SitemapFile) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(f, data, q)
}

func (f *SitemapFile) Fetch() error {
	return bongo.B.Fetch(f)
}

func (f *SitemapFile) UnmarshalBlob() (*ItemSet, error) {
	set := NewItemSet()

	return set, xml.Unmarshal(f.Blob, set)
}

func (f *SitemapFile) Delete() error {
	return bongo.B.Delete(f)
}
