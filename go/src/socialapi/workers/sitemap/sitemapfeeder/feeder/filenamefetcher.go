package feeder

import (
	"fmt"
	"math"
	"socialapi/workers/sitemap/models"
)

type FileNameFetcher interface {
	Fetch(i *models.SitemapItem) string
}

type SimpleNameFetcher struct{}

func (r SimpleNameFetcher) Fetch(i *models.SitemapItem) string {
	return "sitemap"
}

type ModNameFetcher struct{}

func (r ModNameFetcher) Fetch(i *models.SitemapItem) string {
	switch i.TypeConstant {
	case models.TYPE_ACCOUNT:
		return fetchAccountFileName(i.Id)
	case models.TYPE_CHANNEL_MESSAGE:
		return fetchChannelMessageName(i.Id)
	case models.TYPE_CHANNEL:
		return fetchChannelName(i.Id)
	}

	return ""
}

func fetchAccountFileName(id int64) string {
	return fmt.Sprintf("account_%d", id/int64(10000))
}

func fetchChannelMessageName(id int64) string {
	remainder := math.Mod(float64(id), float64(10000))
	return fmt.Sprintf("channel_message_%d", int64(remainder))
}

func fetchChannelName(id int64) string {
	remainder := math.Mod(float64(id), float64(10000))
	return fmt.Sprintf("channel_%d", int64(remainder))
}
