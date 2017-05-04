package models

import (
	"gopkg.in/mgo.v2/bson"
)

const (
	// KDIOGroupName holds the team name of the kd.io service.
	KDIOGroupName = "kd-io"
)

// SubStatus stores the current status of subscription.
type SubStatus string

const (
	// SubStatusTrailing holds trailing subscription status
	SubStatusTrailing SubStatus = "trialing"
	// SubStatusActive holds active subscription status
	SubStatusActive SubStatus = "active"
	// SubStatusPastDue holds past_due subscription status
	SubStatusPastDue SubStatus = "past_due"
	// SubStatusCanceled holds canceled subscription status
	SubStatusCanceled SubStatus = "canceled"
	// SubStatusUnpaid holds unpaid subscription status
	SubStatusUnpaid SubStatus = "unpaid"
)

// Active returns true when subscription is considered to be active.
func (s SubStatus) Active() bool {
	return s == SubStatusActive || s == SubStatusTrailing
}

type Group struct {
	Id                 bson.ObjectId            `bson:"_id" json:"-"`
	Body               string                   `bson:"body" json:"body"`
	Title              string                   `bson:"title" json:"title"`
	Slug               string                   `bson:"slug" json:"slug"`
	Privacy            string                   `bson:"privacy" json:"privacy"`
	Visibility         string                   `bson:"visibility" json:"visibility"`
	SocialApiChannelId string                   `bson:"socialApiChannelId" json:"socialApiChannelId"`
	Parent             []map[string]interface{} `bson:"parent" json:"parent"`
	Customize          map[string]interface{}   `bson:"customize" json:"customize"`
	Counts             map[string]interface{}   `bson:"counts" json:"counts"`
	Migration          string                   `bson:"migration,omitempty" json:"migration"`
	StackTemplate      []string                 `bson:"stackTemplates,omitempty" json:"stackTemplates"`
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
	Status SubStatus `bson:"status" json:"status"`
	ID     string    `bson:"id" json:"id"`
}

// Customer is the group's customer info from payment provider
type Customer struct {
	ID string `bson:"id" json:"id"`
	// IsMember indicates that created customer on stripe is not an admin in the
	// group.
	IsMember string `bson:"isMember" json:"isMember"`
	// HasCard holds the card info of a team
	HasCard bool `bson:"hasCard" json:"hasCard"`
}

// IsSubActive checks if subscription is in valid state for operation
// if env name is default, always responds true
func (g *Group) IsSubActive(env string) bool {
	return IsSubActive(env, g.Payment.Subscription.Status)
}

// IsSubActive implements the business logic for checking if a sub is active. We
// allow everything for default env.
func IsSubActive(env string, subStatus SubStatus) bool {
	const defaultEnv = "default"
	return env == defaultEnv || subStatus.Active()
}
