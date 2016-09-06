package models

import (
	"gopkg.in/mgo.v2/bson"
)

type Group struct {
	Id                             bson.ObjectId            `bson:"_id" json:"-"`
	Body                           string                   `bson:"body" json:"body"`
	Title                          string                   `bson:"title" json:"title"`
	Slug                           string                   `bson:"slug" json:"slug"`
	Privacy                        string                   `bson:"privacy" json:"privacy"`
	Visibility                     string                   `bson:"visibility" json:"visibility"`
	SocialApiChannelId             string                   `bson:"socialApiChannelId" json:"socialApiChannelId"`
	SocialApiAnnouncementChannelId string                   `bson:"socialApiAnnouncementChannelId" json:"socialApiAnnouncementChannelId"`
	SocialApiDefaultChannelId      string                   `bson:"socialApiDefaultChannelId" json:"socialApiDefaultChannelId"`
	Parent                         []map[string]interface{} `bson:"parent" json:"parent"`
	Customize                      map[string]interface{}   `bson:"customize" json:"customize"`
	Counts                         map[string]interface{}   `bson:"counts" json:"counts"`
	Migration                      string                   `bson:"migration,omitempty" json:"migration"`
	StackTemplate                  []string                 `bson:"stackTemplates,omitempty" json:"stackTemplates"`
	// DefaultChannels holds the default channels for a group, when a user joins
	// to this group, participants will be automatically added to regarding
	// channels
	DefaultChannels []string `bson:"defaultChannels,omitempty" json:"defaultChannels"`
	Payment         Payment  `bson:"payment" json:"payment"`
}

type Payment struct {
	Subscription Subscription
	Customer     Customer
}

type Subscription struct {
	// Allowed values are "trialing", "active", "past_due", "canceled", "unpaid".
	Status string `bson:"status" json:"status"`
	ID     string `bson:"id" json:"id"`
}

type Customer struct {
	ID string `bson:"id" json:"id"`
}

// DeletedMember holds information about deleted members from a group.
type DeletedMember struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	AccountID bson.ObjectId `bson:"accountId" json:"accountId"`
	GroupID   bson.ObjectId `bson:"groupId" json:"groupId"`
	// these will be read only during query/modify time, otherwise do not access
	// SubscriptionID string
	// UpdatedAt time.Time
}

// IsSubActive checks if subscription is in valid state for operation
func (g *Group) IsSubActive() bool {
	switch g.Payment.Subscription.Status {
	case "active", "trialing":
		return true
	default:
		return false
	}
}
