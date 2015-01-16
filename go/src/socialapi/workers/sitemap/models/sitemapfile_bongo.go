package models

import "github.com/koding/bongo"

func NewSitemapFile() *SitemapFile {
	return &SitemapFile{}
}

func (f SitemapFile) GetId() int64 {
	return f.Id
}

func (f SitemapFile) BongoName() string {
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

func (f *SitemapFile) Update() error {
	return bongo.B.Update(f)
}

func (f *SitemapFile) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(f, data, q)
}

func (f *SitemapFile) ById(id int64) error {
	return bongo.B.ById(f, id)
}

func (f *SitemapFile) Delete() error {
	return bongo.B.Delete(f)
}
