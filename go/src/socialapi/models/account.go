package models

type Account struct {
	// unique id of the account
	Id int64
}

func NewAccount() *Account {
	return &Account{}
}

func (a *Account) FetchChannels(q *Query) ([]Channel, error) {
	cp := NewChannelParticipant()
	// fetch channel ids
	cids, err := cp.FetchParticipatedChannelIds(a)
	if err != nil {
		return nil, err
	}

	// fetch channels by their ids
	c := NewChannel()
	channels, err := c.FetchByIds(cids)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
