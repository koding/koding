package models

var (
	channelCache map[int64]*Channel
)

func init() {
	channelCache = make(map[int64]*Channel)
}

func ChannelById(id int64) (*Channel, error) {
	if channel, ok := channelCache[id]; ok {
		return channel, nil
	}

	// todo add caching here
	c := NewChannel()
	if err := c.ById(id); err != nil {
		return nil, err
	}

	return c, nil
}

func ChannelsByIds(ids []int64) ([]*Channel, error) {
	channels := make([]*Channel, len(ids))
	if len(channels) == 0 {
		return channels, nil
	}

	for i, id := range ids {
		channel, err := ChannelById(id)
		if err != nil {
			return channels, err
		}
		channels[i] = channel
	}

	return channels, nil
}
