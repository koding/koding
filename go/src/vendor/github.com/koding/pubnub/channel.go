package pubnub

// Channel is used for established subscription connections
type Channel struct {
	Name      string
	messageCh chan Message
	errorCh   chan error
	pr        *PubNubRequest
}

// NewChannel opens a new subscription channel
func (p *PubNubClient) NewChannel(name string) (*Channel, error) {
	if name == "" {
		return nil, ErrChannelNotSet
	}

	channel := &Channel{
		Name:      name,
		messageCh: make(chan Message),
		errorCh:   make(chan error),
	}

	// channel not found
	pr := NewPubNubRequest(name, channel.messageCh, channel.errorCh)
	channel.pr = pr

	go pr.handleResponse()

	// timetoken parameter is not sent for now
	go p.pub.Subscribe(name, "", pr.successCh, false, pr.errorCh)

	if err := pr.Do(); err != nil {
		return nil, err
	}

	return channel, nil
}

func (c *Channel) Consume() <-chan Message {
	return c.messageCh
}

func (c *Channel) ConsumeErrors() <-chan error {
	return c.errorCh
}

func (c *Channel) Close() {
	c.pr.Close()
	close(c.messageCh)
	close(c.errorCh)
}
