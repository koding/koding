package models

import (
	"encoding/xml"
	"fmt"
	"time"
)

type SitemapSet struct {
	XMLName  xml.Name         `xml:"http://www.sitemaps.org/schemas/sitemap/0.9 urlset,name"`
	Sitemaps []ItemDefinition `xml:"sitemap"`
}

func NewSitemapSet(files []SitemapFile, rootURL string) *SitemapSet {
	ss := new(SitemapSet)
	ss.Sitemaps = make([]ItemDefinition, len(files))

	for i := range files {
		ss.Sitemaps[i].Location = fmt.Sprintf("%s.xml", files[i].Name)
		if !files[i].UpdatedAt.IsZero() {
			ss.Sitemaps[i].LastModified = files[i].UpdatedAt.UTC().Format(time.RFC3339)
		}
	}

	return ss
}
