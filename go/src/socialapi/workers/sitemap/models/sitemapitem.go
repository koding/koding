package models

import (
	"fmt"
	"strconv"
	"strings"
)

const (
	STATUS_ADD    = "add"
	STATUS_DELETE = "delete"
	STATUS_UPDATE = "update"
)

type SitemapItem struct {
	Id           int64
	TypeConstant string
	Slug         string
	Status       string
}

func (s *SitemapItem) PrepareSetValue() string {
	return fmt.Sprintf("%d:%s:%s:%s", s.Id, s.TypeConstant, s.Slug, s.Status)
}

// Compose converts value retrieved from cache to sitemapitem
// Value must be in format as: id:type:slug:status
func (s *SitemapItem) Compose(value string) error {
	r := strings.Split(value, ":")
	if len(r) != 4 {
		return fmt.Errorf("wrong value length")
	}

	id, err := strconv.ParseInt(r[0], 0, 64)
	if err != nil {
		return fmt.Errorf("id cannot be cast", err)
	}

	s.Id = id
	s.TypeConstant = r[1]
	s.Slug = r[2]
	s.Status = r[3]

	return nil
}
