// Package sender provides an API for mail sending operations
package emailsender

import (
	"math/rand"
	"socialapi/config"
	"time"

	"github.com/segmentio/analytics-go"
)

var chars = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

func pinGenerateAndSave(username string, conf *config.Config) string {
	pin := pinGenerate()

	identifyUser(username, pin, conf)

	return pin
}

func pinGenerate() string {
	rand.Seed(time.Now().UTC().UnixNano())
	b := make([]rune, 4)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

func identifyUser(username, pin string, conf *config.Config) {
	client := analytics.New(conf.Segment)
	client.Identify(&analytics.Identify{
		UserId: username,
		Traits: map[string]interface{}{
			"pin": pin,
		},
	})
}
