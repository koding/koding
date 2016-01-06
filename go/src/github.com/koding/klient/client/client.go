package client

import (
	"errors"
	"fmt"
	"sync"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
)

func NewPubSub(log kite.Logger) *PubSub {
	return &PubSub{
		Subscriptions: make(map[string]map[int]dnode.Function),
		Log:           log,
	}
}

type PubSub struct {
	// Subscriptions are stored as:
	//
	// Subscriptions[eventName][subIndex]callback
	//
	// The subIndex is the value of subCount at the time of creation. This
	// is used to easily remove a callback, without having to try and compare
	// callback types. The subIndex will always be increasing / incrementing.
	Subscriptions map[string]map[int]dnode.Function

	Log kite.Logger

	// Used to serve as a unique index, for Subscription deletions
	subCount int
	subMu    sync.Mutex
}

// Publish method takes arbitrary event data, and passes it to
// any functions which have subscribed via `client.Subscribe`. The
// only required value is a single `eventName` value. Only listeners
// of the given eventName will be called back with the data.
//
// Examples:
//
//		{
//			"eventName": "fullscreen"
//		}
//
// 		{
// 			"eventName": "openFiles",
// 			"files": ["file1.txt", "file2.txt"]
// 		}
//
// The only response is an error, if any.
func (c *PubSub) Publish(r *kite.Request) (interface{}, error) {
	// Parse the eventName from the incoming data. Note that this method
	// accepts any data beyond eventName, so that this method is as generic
	// as possible.
	var params struct {
		EventName string `json:"eventName"`
	}

	if r.Args == nil {
		return nil, errors.New("client.Publish: Arguments are not passed")
	}

	// The raw response that we'll be publishing to the Client. We're
	// sending the Raw response because, as seen in the params struct,
	// we don't know the data format being passed to client.Publish.
	resp := r.Args.One()

	err := r.Args.One().Unmarshal(&params)
	if err != nil || params.EventName == "" {
		c.Log.Info(fmt.Sprintf(
			"client.Publish: Unknown param format '%s'\n", r.Args.One()))
		return nil, errors.New("client.Publish: eventName is required")
	}

	c.subMu.Lock()
	defer c.subMu.Unlock()

	subs, ok := c.Subscriptions[params.EventName]
	if !ok {
		return nil, errors.New(fmt.Sprintf(
			"client.Publish: No client.Subscribers found for '%s'",
			params.EventName))
	}

	// This condition should never occur - Subscription() should remove
	// all of the subs manually. If it doesn't, something wrong occured
	// during the removal attempt.
	if len(subs) == 0 {
		c.Log.Info(fmt.Sprintf(
			"client.Publish: The event '%s' was found empty, when it should "+
				"have  been removed\n", params.EventName))
		return nil, errors.New(fmt.Sprintf(
			"client.Publish: No client.Subscribers found for '%s'",
			params.EventName))
	}

	c.Log.Info(fmt.Sprintf(
		"client.Publish: Publishing data for event '%s'\n", params.EventName))
	for _, sub := range subs {
		sub.Call(resp)
	}

	return nil, nil
}

// Subscribe method subscribes a function to any `client.Publish`
// calls with the matching eventName.
//
// Example:
//
// 		{
// 			"eventName": "openFiles",
// 			"onPublish": function(){}
// 		}
//
// The only response is an error, if any.
func (c *PubSub) Subscribe(r *kite.Request) (interface{}, error) {
	var params struct {
		EventName string         `json:"eventName"`
		OnPublish dnode.Function `json:"onPublish"`
	}

	if r.Args == nil {
		return nil, errors.New("client.Subscribe: Arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.EventName == "" {
		c.Log.Info(fmt.Sprintf(
			"client.Subscribe: Unknown param format '%s'\n", r.Args.One()))
		return nil, errors.New(
			"client.Subscribe: Expected param format " +
				"{ eventName: [string], onPublish: [function] }")
	}

	if !params.OnPublish.IsValid() {
		return nil, errors.New("client.Subscribe: OnPublish Function is not valid")
	}

	c.subMu.Lock()
	subIndex := c.subCount
	c.subCount++

	if _, ok := c.Subscriptions[params.EventName]; !ok {
		// Init the map if needed
		c.Subscriptions[params.EventName] = map[int]dnode.Function{
			subIndex: params.OnPublish,
		}
	} else {
		c.Subscriptions[params.EventName][subIndex] = params.OnPublish
	}
	c.subMu.Unlock()

	removeSubscription := func() {
		c.subMu.Lock()
		defer c.subMu.Unlock()

		if _, ok := c.Subscriptions[params.EventName]; ok {
			delete(c.Subscriptions[params.EventName], subIndex)
			// Delete the sub map, if there are no more subs in it
			if len(c.Subscriptions[params.EventName]) == 0 {
				delete(c.Subscriptions, params.EventName)
			}
		} else {
			c.Log.Info("client.Subscribe:",
				"Subscriptions could not be found, on Disconnect")
		}
	}

	r.Client.OnDisconnect(removeSubscription)

	return nil, nil
}
