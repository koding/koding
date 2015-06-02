package client

import (
	"errors"
	"fmt"
	"log"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
)

var defaultClientMethods *ClientMethods

func init() {
	defaultClientMethods = &ClientMethods{
		Subscriptions: make(map[string]map[int]dnode.Function),
	}
}

// See ClientMethods.Publish for docs
func Publish(r *kite.Request) (interface{}, error) {
	return defaultClientMethods.Publish(r)
}

// See ClientMethods.Subscribe for docs
func Subscribe(r *kite.Request) (interface{}, error) {
	return defaultClientMethods.Subscribe(r)
}

type ClientMethods struct {
	// Subscriptions are stored as:
	//
	// Subscriptions[eventName][subIndex]callback
	//
	// The subIndex is the value of subCount at the time of creation. This
	// is used to easily remove a callback, without having to try and compare
	// callback types. The subIndex will always be increasing / incrementing.
	Subscriptions map[string]map[int]dnode.Function

	// Used to serve as a unique index, for Subscription deletions
	subCount int
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
func (c *ClientMethods) Publish(r *kite.Request) (interface{}, error) {
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
		log.Printf("client.Publish: Unknown param format '%s'\n", r.Args.One())
		return nil, errors.New("client.Publish: eventName is required")
	}

	subs, _ := c.Subscriptions[params.EventName]
	if len(subs) == 0 {
		return nil, errors.New(fmt.Sprintf(
			"client.Publish: No client.Subscribers found for '%s'",
			params.EventName))
	}

	log.Printf("client.Publish: Publishing data for event '%s'\n",
		params.EventName)
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
func (c *ClientMethods) Subscribe(r *kite.Request) (interface{}, error) {
	var params struct {
		EventName string         `json:"eventName"`
		OnPublish dnode.Function `json:"onPublish"`
	}

	if r.Args == nil {
		return nil, errors.New("client.Subscribe: Arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.EventName == "" {
		log.Printf("client.Subscribe: Unknown param format '%s'\n", r.Args.One())
		return nil, errors.New(
			"client.Subscribe: Expected param format " +
				"{ eventName: [string], onPublish: [function] }")
	}

	if params.OnPublish.IsValid() {
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

		removeSubscription := func() {
			if _, ok := c.Subscriptions[params.EventName]; ok {
				delete(c.Subscriptions[params.EventName], subIndex)
			} else {
				log.Println("client.Subscribe:",
					"Subscriptions could not be found, on Disconnect")
			}
		}

		r.Client.OnDisconnect(removeSubscription)
	}

	return nil, nil
}
