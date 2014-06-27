package handlers

import (
	"socialapi/workers/api/modules/account"
	"socialapi/workers/api/modules/activity"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/interaction"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"
	"socialapi/workers/api/modules/popular"
	"socialapi/workers/api/modules/privatemessage"
	"socialapi/workers/api/modules/reply"
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

func Inject(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// Message Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	mux.Handle("POST", "/message/{id}", handler.Wrapper(message.Update, "message-update"))
	mux.Handle("DELETE", "/message/{id}", handler.Wrapper(message.Delete, "message-delete"))
	mux.Handle("GET", "/message/{id}", handler.Wrapper(message.Get, "message-get"))
	mux.Handle("GET", "/message/slug/{slug}", handler.Wrapper(message.GetBySlug, "message-get-by-slug"))
	mux.Handle("GET", "/message/{id}/related", handler.Wrapper(message.GetWithRelated, "message-get-with-related"))

	////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////// Message Reply Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	mux.Handle("POST", "/message/{id}/reply", handler.Wrapper(reply.Create, "reply-create"))
	mux.Handle("GET", "/message/{id}/reply", handler.Wrapper(reply.List, "reply-list"))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////// Message Interaction Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	mux.Handle("POST", "/message/{id}/interaction/{type}/add", handler.Wrapper(interaction.Add, "interactions-add"))
	mux.Handle("POST", "/message/{id}/interaction/{type}/delete", handler.Wrapper(interaction.Delete, "interactions-delete"))
	// get all the interactions for message
	mux.Handle("GET", "/message/{id}/interaction/{type}", handler.Wrapper(interaction.List, "interactions-list-typed"))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// Channel Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////

	mux.Handle("POST", "/channel", handler.Wrapper(channel.Create, "channel-create"))
	mux.Handle("GET", "/channel", handler.Wrapper(channel.List, "channel-list"))
	mux.Handle("GET", "/channel/search", handler.Wrapper(channel.Search, "channel-search"))
	mux.Handle("GET", "/channel/name/{name}", handler.Wrapper(channel.ByName, "channel-get-byname"))
	mux.Handle("GET", "/channel/checkparticipation", handler.Wrapper(channel.CheckParticipation, "channel-check-participation"))

	// deprecated, here for socialworker
	mux.Handle("POST", "/channel/{id}", handler.Wrapper(channel.Update, "channel-update"))
	mux.Handle("POST", "/channel/{id}/update", handler.Wrapper(channel.Update, "channel-update"))
	mux.Handle("POST", "/channel/{id}/delete", handler.Wrapper(channel.Delete, "channel-delete"))
	mux.Handle("GET", "/channel/{id}", handler.Wrapper(channel.Get, "channel-get"))
	// add a new messages to the channel
	mux.Handle("POST", "/channel/{id}/message", handler.Wrapper(message.Create, "channel-message-create"))
	// list participants of the channel
	mux.Handle("GET", "/channel/{id}/participant", handler.Wrapper(participant.List, "participant-list"))
	// add participant to the channel
	mux.Handle("POST", "/channel/{id}/participant/{accountId}/add", handler.Wrapper(participant.Add, "participant-list"))
	// remove participant from the channel
	mux.Handle("POST", "/channel/{id}/participant/{accountId}/delete", handler.Wrapper(participant.Delete, "participant-list"))
	mux.Handle("POST", "/channel/{id}/participant/{accountId}/presence", handler.Wrapper(participant.Presence, "participant-presence"))

	// list messages of the channel
	mux.Handle("GET", "/channel/{id}/history", handler.Wrapper(messagelist.List, "channel-history-list"))
	// message count of the channel
	mux.Handle("GET", "/channel/{id}/history/count", handler.Wrapper(messagelist.Count, "channel-history-count"))
	// register an account
	mux.Handle("POST", "/account", handler.Wrapper(account.Register, "account-create"))
	// list channels of the account
	mux.Handle("GET", "/account/{id}/channels", handler.Wrapper(account.ListChannels, "account-channel-list"))
	// list posts of the account
	mux.Handle("GET", "/account/{id}/posts", handler.Wrapper(account.ListPosts, "account-post-list"))
	// follow the account
	mux.Handle("POST", "/account/{id}/follow", handler.Wrapper(account.Follow, "account-follow"))
	// un-follow the account
	mux.Handle("POST", "/account/{id}/unfollow", handler.Wrapper(account.Unfollow, "account-unfollow"))

	// fetch profile feed
	// mux.Handle("GET", "/account/{id}/profile/feed", handler.Wrapper(account.ListProfileFeed, "list-profile-feed"))
	// get pinning channel of the account
	mux.Handle("GET", "/activity/pin/channel", handler.Wrapper(activity.GetPinnedActivityChannel, "activity-pin-get-channel"))
	// get pinning channel of the account
	mux.Handle("GET", "/activity/pin/list", handler.Wrapper(activity.List, "activity-pin-list-message"))
	// pin a new status update
	mux.Handle("POST", "/activity/pin/add", handler.Wrapper(activity.PinMessage, "activity-add-pinned-message"))
	// unpin a status update
	mux.Handle("POST", "/activity/pin/remove", handler.Wrapper(activity.UnpinMessage, "activity-remove-pinned-message"))

	// @todo add tests
	mux.Handle("POST", "/activity/pin/glance", handler.Wrapper(activity.Glance, "activity-pinned-message-glance"))
	// get popular topics
	mux.Handle("GET", "/popular/topics/{statisticName}", handler.Wrapper(popular.ListTopics, "list-popular-topics"))
	mux.Handle("GET", "/popular/posts/{channelName}/{statisticName}", handler.Wrapper(popular.ListPosts, "list-popular-posts"))

	mux.Handle("POST", "/privatemessage/send", handler.Wrapper(privatemessage.Send, "privatemessage-send"))
	mux.Handle("GET", "/privatemessage/list", handler.Wrapper(privatemessage.List, "privatemessage-list"))

	return mux
}

// to-do list
// get current account from context for future
// like client.connection.delegate
