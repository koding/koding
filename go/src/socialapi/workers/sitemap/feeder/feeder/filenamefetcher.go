package sitemapfeeder

type FileNameFetcher interface {
	Fetch(i *SitemapItem) string
}

type SimpleNameFetcher struct{}

func (s SimpleNameFetcher) Fetch(i *SitemapItem) string {
	// TODO implement this
	return "firstfile"
}
