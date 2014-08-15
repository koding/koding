package rest

import (
	"socialapi/models"
)

type CreatePostType struct {
	ChannelId, Acc1Id, Acc2Id int64
	Body                      string
}

func NewCreatePost(channelId, acc1Id, acc2Id int64) *CreatePostType {
	return &CreatePostType{
		ChannelId: channelId,
		Acc1Id:    acc1Id,
		Acc2Id:    acc2Id,
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

func (c *CreatePostType) CreateReply() (*CreatePostReplyReturn, error) {
	return c.CreateReplies(1)
}

func (c *CreatePostType) CreateReplies(n int) (*CreatePostReplyReturn, error) {
	cpReturn, err := c.Do()
	if err != nil {
		return nil, err
	}

	cpReturn.Replies = make([]*models.ChannelMessage, 0)

	for i := 1; i <= n; i++ {
		reply, err := AddReply(cpReturn.Post.Id, c.Acc2Id, c.ChannelId)
		if err != nil {
			return nil, err
		}

		cpReturn.Replies = append(cpReturn.Replies, reply)
	}

	return cpReturn, nil
}
