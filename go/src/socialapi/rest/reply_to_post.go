package rest

import (
	"socialapi/models"
)

type CreatePostType struct {
	ChannelId, Acc1Id, Acc2Id int64
	Body, Token               string
}

func NewCreatePost(channelId, acc1Id, acc2Id int64, token string) *CreatePostType {
	return &CreatePostType{
		ChannelId: channelId,
		Acc1Id:    acc1Id,
		Acc2Id:    acc2Id,
		Token:     token,
	}
}

type CreatePostReplyReturn struct {
	Post    *models.ChannelMessage
	Replies []*models.ChannelMessage
}

func (c *CreatePostType) Do() (*CreatePostReplyReturn, error) {
	cm, err := CreatePostWithBody(c.ChannelId, c.Acc1Id, "create a message")
	return &CreatePostReplyReturn{Post: cm}, err
}
