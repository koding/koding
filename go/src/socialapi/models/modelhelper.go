package models

import (
	"fmt"
	"math/rand"
	"strconv"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/stvp/slug"
)

// todo do not create slugs for "Replies" and "Chat Messages"
func Slugify(message *ChannelMessage) (*ChannelMessage, error) {
	// we want hypen between our words
	slug.Replacement = '-'
	res := NewChannelMessage()

	sugguestedSlug := slug.Clean(message.Body)
	query := map[string]interface{}{
		"slug": sugguestedSlug,
	}

	for tryCount := 0; tryCount < 10; tryCount++ {
		if err := bongo.B.One(message, res, query); err != nil {
			// if we got error from db, it means it couldnt find the
			// data, so we can return here
			if err != gorm.RecordNotFound {
				return nil, err
			}
			message.Slug = sugguestedSlug
			return message, nil
		}
		// iterate with the new slug
		sugguestedSlug = sugguestedSlug + "-" + strconv.Itoa(rand.Intn(1000))
		query["slug"] = sugguestedSlug
	}

	return nil, fmt.Errorf("Couldnt generate unique slug:%s", message.Slug)
}
