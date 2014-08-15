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

func (c *CreatePostType) WithReply() (*CreatePostReplyReturn, error) {
	return c.WithReplies(1)
}

func (c *CreatePostType) WithReplies(count int) (*CreatePostReplyReturn, error) {
	cReply, err := c.Do()
	if err != nil {
		return nil, err
	}

	cReply.Replies = make([]*models.ChannelMessage, 0)

	for i := 1; i <= count; i++ {
		reply, err := AddReply(cReply.Post.Id, c.Acc1Id, c.ChannelId)
		if err != nil {
			return nil, err
		}

		cReply.Replies = append(cReply.Replies, reply)
	}

	return cReply, nil
}
