package models

import (
	"socialapi/request"
	"sync"
)

type ChannelContainer struct {
	Channel             *Channel `json:"channel"`
	IsParticipant       bool     `json:"isParticipant"`
	ParticipantCount    int      `json:"participantCount"`
	ParticipantsPreview []string `json:"participantsPreview"`
	AccountOldId        string   `json:"accountOldId"`
	UnreadCount         int      `json:"unreadCount"`
	Err                 error    `json:"-"`
}

// Inits channel
//
// Tests are done
func NewChannelContainer() *ChannelContainer {
	return &ChannelContainer{}
}

// Tests are done
func (c *ChannelContainer) BongoName() string {
	return "api.channel"
}

func (c *ChannelContainer) Fetch(id int64, q *request.Query) error {
	cc, err := BuildChannelContainer(id, q)
	if err != nil {
		return err
	}
	*c = *cc

	return nil
}

// GetId fetch the id of the channel
//
// Tests are done
func (c *ChannelContainer) GetId() int64 {
	if c.Channel != nil {
		return c.Channel.Id
	}

	return 0
}

func (cr *ChannelContainer) PopulateWith(c Channel, accountId int64) error {
	cr.Channel = &c
	cr.AddParticipantCount().
		AddParticipantsPreview().
		AddIsParticipant(accountId).
		AddAccountOldId()

	return cr.Err
}

func withChecks(cc *ChannelContainer, f func(c *ChannelContainer) error) *ChannelContainer {
	if cc == nil {
		cc = &ChannelContainer{}
		cc.Err = ErrChannelContainerIsNotSet
		return cc
	}

	if cc.Err != nil {
		return cc
	}

	if cc.Channel == nil {
		cc.Err = ErrChannelIsNotSet
		return cc
	}

	cc.Err = f(cc)

	return cc
}

func (cr *ChannelContainer) AddAccountOldId() *ChannelContainer {
	return withChecks(cr, func(c *ChannelContainer) error {
		if c.AccountOldId != "" {
			return nil
		}

		acc, err := Cache.Account.ById(c.Channel.CreatorId)
		if err != nil {
			return err
		}

		c.AccountOldId = acc.OldId

		return nil
	})
}
func (cr *ChannelContainer) AddParticipantCount() *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id
		// fetch participant count from db
		participantCount, err := cp.FetchParticipantCount()
		if err != nil {
			return err
		}

		cc.ParticipantCount = participantCount
		return nil
	})
}

func (cr *ChannelContainer) AddParticipantsPreview() *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		maxParticipantCount := 5
		// try to use the data
		if cc.ParticipantCount > maxParticipantCount {
			if len(cc.ParticipantsPreview) == maxParticipantCount {
				return nil
			}
		}

		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id

		// get participant preview
		cpList, err := cp.ListAccountIds(maxParticipantCount)
		if err != nil {
			return err
		}

		// get their old mongo ids from system
		participantOldIds, err := FetchAccountOldsIdByIdsFromCache(cpList)
		if err != nil {
			return err
		}

		cc.ParticipantsPreview = participantOldIds

		return nil
	})
}

func (cr *ChannelContainer) AddIsParticipant(accountId int64) *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		if accountId == 0 {
			return nil
		}

		// if data is already set, use it
		if cc.IsParticipant {
			return nil
		}

		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id

		// add participation status
		isParticipant, err := cp.IsParticipant(accountId)
		if err != nil {
			return err
		}

		cc.IsParticipant = isParticipant

		return nil
	})
}

func getChannelParticipant(channelId, accountId int64) (*ChannelParticipant, error) {
	// fetch participant data from db
	cp := NewChannelParticipant()
	cp.ChannelId = channelId
	cp.AccountId = accountId
	if err := cp.FetchParticipant(); err != nil {
		return nil, err
	}

	return cp, nil
}

type ChannelContainers []ChannelContainer

func NewChannelContainers() *ChannelContainers {
	return &ChannelContainers{}
}

type PopularChannelContainerResp struct {
	Index int
	Data  *ChannelContainer
}

func (c *ChannelContainers) PopulateWith(channelList []Channel, accountId int64) *ChannelContainers {
	var wg sync.WaitGroup
	var channelListLen = len(channelList)

	var onChannel = make(chan *PopularChannelContainerResp, channelListLen)

	for i := range channelList {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()

			cc := NewChannelContainer()
			cc.PopulateWith(channelList[i], accountId)

			onChannel <- &PopularChannelContainerResp{Index: i, Data: cc}
		}(i)
	}

	wg.Wait()

	var temporaryChannelContainer = make([]*ChannelContainer, channelListLen)

	// the order of channels matters, however since the results are fetched in
	// parallel above we keep track of the original index and insert them in the
	// right place
	for i := 1; i <= channelListLen; i++ {
		resp := <-onChannel
		temporaryChannelContainer[resp.Index] = resp.Data
	}

	for _, channel := range temporaryChannelContainer {
		c.Add(channel)
	}

	return c
}

func (c *ChannelContainers) Fetch(channelList []Channel, query *request.Query) error {
	for i := range channelList {
		cc := NewChannelContainer()
		if err := cc.Fetch(channelList[i].GetId(), query); err != nil {
			cc.Err = err
		}
		c.Add(cc)
	}

	return nil
}

func (c *ChannelContainers) AddIsParticipant(accountId int64) *ChannelContainers {
	for i, container := range *c {
		(*c)[i] = *container.AddIsParticipant(accountId)
	}

	return c
}

func (c *ChannelContainers) Add(containers ...*ChannelContainer) {
	for _, cc := range containers {
		*c = append(*c, *cc)
	}
}

func (c ChannelContainers) Err() error {
	for _, container := range c {
		if container.Err != nil {
			return container.Err
		}
	}

	// // TODO filter or re-populate err-ed content

	return nil
}
