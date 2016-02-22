package models

import (
	"encoding/xml"
	"fmt"
	"socialapi/config"
	"time"
)

type SitemapSet struct {
	XMLName  xml.Name         `xml:"http://www.sitemaps.org/schemas/sitemap/0.9 sitemapindex,name"`
	Sitemaps []ItemDefinition `xml:"sitemap"`
}

func NewSitemapSet(files []SitemapFile, rootURL string) *SitemapSet {
	ss := &SitemapSet{}
	ss.Sitemaps = make([]ItemDefinition, len(files))

	for i := range files {
		uri := config.MustGet().Hostname
		protocol := config.MustGet().Protocol
		ss.Sitemaps[i].Location = fmt.Sprintf("%s//%s/%s", protocol, uri, GetSitemapLocation(files[i]))
		if !files[i].UpdatedAt.IsZero() {
			ss.Sitemaps[i].LastModified = files[i].UpdatedAt.UTC().Format(time.RFC3339)
		}
	}

	return ss
}

func GetSitemapLocation(file SitemapFile) string {
	if file.isStatic {
		return file.Name
	}

	return fmt.Sprintf("sitemap/%s.xml", file.Name)
}
