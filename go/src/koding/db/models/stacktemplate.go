package models

import (
	"time"

	"gopkg.in/mgo.v2/bson"
)

// StackTemplateConfig represents jStackTemplate.config field.
type StackTemplateConfig struct {
	RequiredData      map[string][]string `bson:"requiredData"`
	RequiredProviders []string            `bson:"requiredProviders"`
	Verified          bool                `bson:"verified"`
}

const (
	AccessPrivate = "private"
	AccessGroup   = "group"
	AccessPublic  = "public"
)

// StackTemplate is a document from jStackTemplates collection
type StackTemplate struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	AccessLevel string        `bson:"accessLevel"`

	Template struct {
		Content    string `bson:"content"`
		RawContent string `bson:"rawContent"`
		Sum        string `bson:"sum"`
		Details    bson.M `bson:"details"`
	} `bson:"template"`

	Config      *StackTemplateConfig `bson:"config"`
	Credentials map[string][]string  `bson:"credentials"`
	Description string               `bson:"description"`
	Group       string               `bson:"group"`
	Machines    []bson.M             `bson:"machines"`
	Meta        bson.M               `bson:"meta"`
	OriginID    bson.ObjectId        `bson:"originId"`
	Title       string               `bson:"title"`
}

func NewStackTemplate(provider, identifier string) *StackTemplate {
	now := time.Now().UTC()

	return &StackTemplate{
		Id:          bson.NewObjectId(),
		AccessLevel: "private",
		Config: &StackTemplateConfig{
			RequiredData: map[string][]string{
				"user":  {"username"},
				"group": {"slug"},
			},
			RequiredProviders: []string{
				"koding",
				provider,
			},
			Verified: true,
		},
		Credentials: map[string][]string{
			provider: {identifier},
		},
		Description: "##### Readme text for this stack template\n\nYou can write" +
			" down a readme text for new users.\nThis text will be shown when they " +
			"want to use this stack.\nYou can use markdown with the readme content.\n\n",
		Meta: bson.M{
			"createdAt":  now,
			"modifiedAt": now,
			"tags":       nil,
			"views":      nil,
			"votes":      nil,
			"likes":      0,
		},
	}

}
