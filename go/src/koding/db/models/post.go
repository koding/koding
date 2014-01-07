package models

import "labix.org/v2/mgo/bson"

type Post struct {
	Id           bson.ObjectId            `bson:"_id"`
	Body         string                   `bson:"body"`
	Slug         string                   `bson:"slug,omitempty"`
	Group        string                   `bson:"group,omitempty"`
	OriginId     bson.ObjectId            `bson:"originId"`
	OriginType   string                   `bson:"originType"`
	RepliesCount int                      `bson:"repliesCount"`
	Title        string                   `bson:"title,omitempty"`
	OpinionCount int                      `bson:"opinionCount,omitempty"`
	Counts       Count                    `bson:"counts"`
	Attachments  []map[string]interface{} `bson:"attachments"`
	Meta         Meta                     `bson:"meta"`
	Link         map[string]interface{}   `bson:"link"`
}

func (p *Post) ConvertToStatusUpdate() *StatusUpdate {
	return &StatusUpdate{
		Id:           p.Id,
		Slug:         p.Slug,
		Body:         p.Body,
		OriginId:     p.OriginId,
		OriginType:   p.OriginType,
		Meta:         p.Meta,
		RepliesCount: 0,
		Group:        p.Group,
		Counts:       p.Counts,
		Attachments:  p.Attachments,
		Link:         p.Link,
	}
}
