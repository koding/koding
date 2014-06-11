package feeder

import "socialapi/workers/sitemap/models"

type FileNameFetcher interface {
	Fetch(i *models.SitemapItem) string
}

type SimpleNameFetcher struct{}

func (s SimpleNameFetcher) Fetch(i *models.SitemapItem) string {
	// TODO implement this
	return "firstfile"
}
