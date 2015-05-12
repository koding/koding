package models

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/dchest/uniuri"
	"github.com/koding/bongo"
	"github.com/stvp/slug"
)

// todo fix slug generation with the slugifiable.coffee implementation
func Slugify(message *ChannelMessage) (*ChannelMessage, error) {

	if message.TypeConstant != ChannelMessage_TYPE_POST {
		return message, nil
	}

	// we want hypen between our words
	slug.Replacement = '-'
	res := NewChannelMessage()

	suggestedSlug := slug.Clean(message.Body)
	if len(suggestedSlug) > 80 {
		suggestedSlug = suggestedSlug[:79]
	}

	query := map[string]interface{}{
		"slug": suggestedSlug,
	}

	rand.Seed(time.Now().UnixNano())

	for tryCount := 0; tryCount < 10; tryCount++ {
		if err := res.One(bongo.NewQS(query)); err != nil {
			// if we got error from db, it means it couldnt find the
			// data, so we can return here
			if err != bongo.RecordNotFound {
				return nil, err
			}
			message.Slug = suggestedSlug
			return message, nil
		}
		// iterate with the new slug
		// this is not the best strategy to generate slug
		// but also not the worst
		suggestedSlug = suggestedSlug + "-" + strconv.Itoa(rand.Intn(1000000000))
		query["slug"] = suggestedSlug
	}

	return nil, fmt.Errorf("couldnt generate unique slug:%s", message.Slug)
}

func RandomName() string {
	return uniuri.New()
}

func RandomGroupName() string {
	rand.Seed(time.Now().UnixNano())
	return "group" + strconv.FormatInt(rand.Int63(), 10)
}

func ZeroDate() time.Time {
	return time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)
}
