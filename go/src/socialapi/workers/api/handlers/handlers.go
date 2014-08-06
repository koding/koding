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
	mux.Handle("POST", "/message/{id}", handler.Wrapper(message.Update, "message-update", false))
	mux.Handle("DELETE", "/message/{id}", handler.Wrapper(message.Delete, "message-delete", false))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/{id}", handler.Wrapper(message.Get, "message-get", true))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/slug/{slug}", handler.Wrapper(message.GetBySlug, "message-get-by-slug", true))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/{id}/related", handler.Wrapper(message.GetWithRelated, "message-get-with-related", false))

	////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////// Message Reply Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	mux.Handle("POST", "/message/{id}/reply", handler.Wrapper(reply.Create, "reply-create", true))
	// exempt contents are filtered
	mux.Handle("GET", "/message/{id}/reply", handler.Wrapper(reply.List, "reply-list", true))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////// Message Interaction Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	mux.Handle("POST", "/message/{id}/interaction/{type}/add", handler.Wrapper(interaction.Add, "interactions-add", false))
	mux.Handle("POST", "/message/{id}/interaction/{type}/delete", handler.Wrapper(interaction.Delete, "interactions-delete", false))
	// get all the interactions for message
	// exempt contents are filtered
	mux.Handle("GET", "/message/{id}/interaction/{type}", handler.Wrapper(interaction.List, "interactions-list-typed", false))

	////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// Channel Operations /////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////

	mux.Handle("POST", "/channel", handler.Wrapper(channel.Create, "channel-create", true))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel", handler.Wrapper(channel.List, "channel-list", false))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/search", handler.Wrapper(channel.Search, "channel-search", false))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/name/{name}", handler.Wrapper(channel.ByName, "channel-get-byname", false))
	mux.Handle("GET", "/channel/checkparticipation", handler.Wrapper(channel.CheckParticipation, "channel-check-participation", false))

	// deprecated, here for socialworker
	mux.Handle("POST", "/channel/{id}", handler.Wrapper(channel.Update, "channel-update-old", false))
	mux.Handle("POST", "/channel/{id}/update", handler.Wrapper(channel.Update, "channel-update", false))
	mux.Handle("POST", "/channel/{id}/delete", handler.Wrapper(channel.Delete, "channel-delete", false))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/{id}", handler.Wrapper(channel.Get, "channel-get", false))

	// add a new messages to the channel
	mux.Handle("POST", "/channel/{id}/message", handler.Wrapper(message.Create, "channel-message-create", false))

	// exempt contents are filtered
	mux.Handle("GET", "/channel/{id}/participants", handler.Wrapper(participant.List, "participant-list", false))
	mux.Handle("POST", "/channel/{id}/participants/add", handler.Wrapper(participant.AddMulti, "participant-multi-add", false))
	mux.Handle("POST", "/channel/{id}/participants/remove", handler.Wrapper(participant.RemoveMulti, "participant-multi-remove", false))
	mux.Handle("POST", "/channel/{id}/participant/{accountId}/presence", handler.Wrapper(participant.UpdatePresence, "participant-presence-update", false))

	// list messages of the channel
	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/{id}/history", handler.Wrapper(messagelist.List, "channel-history-list", false))

	// message count of the channel
	mux.Handle("GET", "/channel/{id}/history/count", handler.Wrapper(messagelist.Count, "channel-history-count", false))
	// register an account
	mux.Handle("POST", "/account", handler.Wrapper(account.Register, "account-create", false))

	// added troll mode protection
	// list channels of the account
	mux.Handle("GET", "/account/{id}/channels", handler.Wrapper(account.ListChannels, "account-channel-list", false))
	// list posts of the account
	mux.Handle("GET", "/account/{id}/posts", handler.Wrapper(account.ListPosts, "account-post-list", false))
	// follow the account
	mux.Handle("POST", "/account/{id}/follow", handler.Wrapper(account.Follow, "account-follow", false))
	// un-follow the account
	mux.Handle("POST", "/account/{id}/unfollow", handler.Wrapper(account.Unfollow, "account-unfollow", false))

	// fetch profile feed
	// mux.Handle("GET", "/account/{id}/profile/feed", handler.Wrapper(account.ListProfileFeed, "list-profile-feed", false))
	// get pinning channel of the account
	mux.Handle("GET", "/activity/pin/channel", handler.Wrapper(activity.GetPinnedActivityChannel, "activity-pin-get-channel", false))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/activity/pin/list", handler.Wrapper(activity.List, "activity-pin-list-message", false))
	// pin a new status update
	mux.Handle("POST", "/activity/pin/add", handler.Wrapper(activity.PinMessage, "activity-add-pinned-message", false))
	// unpin a status update
	mux.Handle("POST", "/activity/pin/remove", handler.Wrapper(activity.UnpinMessage, "activity-remove-pinned-message", false))

	// @todo add tests
	mux.Handle("POST", "/activity/pin/glance", handler.Wrapper(activity.Glance, "activity-pinned-message-glance", false))

	// get popular topics
	// exempt contents are filtered
	// TODO add caching
	mux.Handle("GET", "/popular/topics/{statisticName}", handler.Wrapper(popular.ListTopics, "list-popular-topics", false))

	// exempt contents are filtered
	// TODO add caching
	mux.Handle("GET", "/popular/posts/{channelName}/{statisticName}", handler.Wrapper(popular.ListPosts, "list-popular-posts", false))

	mux.Handle("POST", "/privatemessage/init", handler.Wrapper(privatemessage.Init, "privatemessage-init", false))

	mux.Handle("POST", "/privatemessage/send", handler.Wrapper(privatemessage.Send, "privatemessage-send", false))

	// exempt contents are filtered
	mux.Handle("GET", "/privatemessage/list", handler.Wrapper(privatemessage.List, "privatemessage-list", false))

	return mux
}

// to-do list
// get current account from context for future
// like client.connection.delegate
