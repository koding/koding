package models

import (
	"encoding/xml"
	"errors"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/cache"
)

var (
	ErrTypeCast     = errors.New("type cast error")
	ErrNotFound     = errors.New("not found")
	ErrEmptyContent = errors.New("empty content")
)

type SitemapFetcher struct {
	cache    *cache.MemoryTTL
	hostname string
}

func NewSitemapFetcher(ttl, gcInterval time.Duration, hostname string) *SitemapFetcher {
	sitemapCache := cache.NewMemoryWithTTL(ttl)
	sitemapCache.StartGC(gcInterval)

	return &SitemapFetcher{
		cache:    sitemapCache,
		hostname: hostname,
	}
}

func (fc *SitemapFetcher) FetchRoot() ([]byte, error) {

	rootSitemapKey := "root"
	filesByte, err := fc.fetchFromCache(rootSitemapKey)
	if err == nil {
		return filesByte, nil
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	sf := NewSitemapFile()

	files, err := sf.FetchAll()
	if err != nil {
		return nil, err
	}

	staticFiles := fc.CreateStaticPages()
	files = append(files, staticFiles...)

	set := NewSitemapSet(files, fc.hostname)

	res, err := xml.Marshal(set)
	if err != nil {
		return nil, err
	}

	fc.cache.Set(rootSitemapKey, res)

	return res, nil
}

func (fc *SitemapFetcher) CreateStaticPages() []SitemapFile {
	pages := make([]SitemapFile, len(staticPages))
	for i, page := range staticPages {
		pages[i].Name = page
		pages[i].isStatic = true
	}

	return pages
}

func (fc *SitemapFetcher) FetchByName(fileName string) ([]byte, error) {
	file, err := fc.fetchFromCache(fileName)
	if err == nil {
		return file, nil
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	sf := NewSitemapFile()
	if err := sf.ByName(fileName); err != nil {
		if err == bongo.RecordNotFound {
			return nil, ErrNotFound
		}

		return nil, err
	}

	if sf.Blob == nil || len(sf.Blob) == 0 {
		return nil, ErrEmptyContent
	}

	fc.cache.Set(fileName, sf.Blob)

	return sf.Blob, nil
}

func (fc *SitemapFetcher) fetchFromCache(fileName string) ([]byte, error) {
	file, err := fc.cache.Get(fileName)
	if err != nil {
		return nil, err
	}

	res, ok := file.([]byte)
	if !ok {
		return nil, ErrTypeCast
	}

	return res, nil
}
