package models

import (
	"fmt"
	"strconv"
	"strings"
)

const (
	TYPE_CHANNEL_MESSAGE = "channelmessage"
	TYPE_CHANNEL         = "channel"
	STATUS_ADD           = "add"
	STATUS_DELETE        = "delete"
	STATUS_UPDATE        = "update"
)

// Used as a auxiliary for forming xml data
type SitemapItem struct {
	Id           int64
	TypeConstant string
	Slug         string
	Status       string
}

func NewSitemapItem() *SitemapItem {
	return &SitemapItem{}
}

func (s *SitemapItem) PrepareSetValue() string {
	return fmt.Sprintf("%d:%s:%s:%s", s.Id, s.TypeConstant, s.Slug, s.Status)
}

// Populate converts value retrieved from cache to sitemapitem
// Value must be in format as: id:type:slug:status
func (s *SitemapItem) Populate(value string) error {
	r := strings.Split(value, ":")
	if len(r) != 4 {
		return fmt.Errorf("wrong value length")
	}

	id, err := strconv.ParseInt(r[0], 0, 64)
	if err != nil {
		return fmt.Errorf("id cannot be cast %s", err)
	}

	s.Id = id
	s.TypeConstant = r[1]
	s.Slug = r[2]
	s.Status = r[3]

	return nil
}

func (s *SitemapItem) Definition(protocol, rootURL string) *ItemDefinition {
	d := &ItemDefinition{}
	d.Location = s.composeLocation(protocol, rootURL)

	return d
}

func (s *SitemapItem) composeLocation(protocol, rootURL string) string {
	switch s.TypeConstant {
	case TYPE_CHANNEL_MESSAGE:
		return fmt.Sprintf("%s//%s/%s/%s", protocol, rootURL, "Activity", s.Slug)
	case TYPE_CHANNEL:
		return fmt.Sprintf("%s//%s/%s/%s", protocol, rootURL, "Activity", s.Slug)
	}

	return ""
}
