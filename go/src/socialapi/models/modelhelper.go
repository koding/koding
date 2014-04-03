package models

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/jinzhu/gorm"
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

	sugguestedSlug := slug.Clean(message.Body)
	if len(sugguestedSlug) > 80 {
		sugguestedSlug = sugguestedSlug[:79]
	}

	query := map[string]interface{}{
		"slug": sugguestedSlug,
	}

	rand.Seed(time.Now().UnixNano())

	for tryCount := 0; tryCount < 10; tryCount++ {
		if err := bongo.B.One(message, res, query); err != nil {
			// if we got error from db, it means it couldnt find the
			// data, so we can return here
			if err != gorm.RecordNotFound {
				return nil, err
			}
			message.Slug = sugguestedSlug
			// message.Slug = &sugguestedSlug
			// message.Slug.String = sugguestedSlug
			// message.Slug.Valid = true
			return message, nil
		}
		// iterate with the new slug
		// this is not the best strategy to generate slug
		// but also not the worst
		sugguestedSlug = sugguestedSlug + "-" + strconv.Itoa(rand.Intn(1000000000))
		query["slug"] = sugguestedSlug
	}

	return nil, fmt.Errorf("Couldnt generate unique slug:%s", message.Slug)
}
