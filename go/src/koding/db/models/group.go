package models

import (
	"gopkg.in/mgo.v2/bson"
)

const (
	// KDIOGroupName holds the team name of the kd.io service.
	KDIOGroupName = "kd-io"

	// PaymentStatusActive holds active payment status
	PaymentStatusActive = "active"

	// PaymentStatusTrailing holds trailing payment status
	PaymentStatusTrailing = "trialing"
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

// Payment is general container for payment info
type Payment struct {
	Subscription Subscription
	Customer     Customer
}

// Subscription holds customer-plan subscription related info
type Subscription struct {
	// Allowed values are "trialing", "active", "past_due", "canceled", "unpaid".
	Status string `bson:"status" json:"status"`
	ID     string `bson:"id" json:"id"`
}

// Customer is the group's customer info from payment provider
type Customer struct {
	ID string `bson:"id" json:"id"`
	// IsMember indicates that created customer on stripe is not an admin in the
	// group.
	IsMember string `bson:"isMember" json:"isMember"`
}

// IsSubActive checks if subscription is in valid state for operation
func (g *Group) IsSubActive() bool {
	switch g.Payment.Subscription.Status {
	case PaymentStatusActive, PaymentStatusTrailing:
		return true
	default:
		return false
	}
}
