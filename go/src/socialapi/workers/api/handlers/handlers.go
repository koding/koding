package handlers

import (
	"socialapi/models"
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

	"github.com/koding/metrics"
	tigertonic "github.com/rcrowley/go-tigertonic"
)

func Inject(mux *tigertonic.TrieServeMux, metrics *metrics.Metrics) *tigertonic.TrieServeMux {
	//----------------------------------------------------------
	// Message Operations
	//----------------------------------------------------------
	mux.Handle("POST", "/message/{id}", handler.Wrapper(
		handler.Request{
			Handler:        message.Update,
			Name:           "message-update",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))

	mux.Handle("DELETE", "/message/{id}", handler.Wrapper(
		handler.Request{
			Handler:        message.Delete,
			Name:           "message-delete",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/{id}", handler.Wrapper(
		handler.Request{
			Handler: message.Get,
			Name:    "message-get",
			Securer: models.MessageSecurer,
			Metrics: metrics,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/slug/{slug}", handler.Wrapper(
		handler.Request{
			Handler: message.GetBySlug,
			Name:    "message-get-by-slug",
			Metrics: metrics,
			Securer: models.MessageSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/message/{id}/related", handler.Wrapper(
		handler.Request{
			Handler: message.GetWithRelated,
			Name:    "message-get-with-related",
			Metrics: metrics,
			Securer: models.MessageSecurer,
		},
	))

	//----------------------------------------------------------
	// Message Reply Operations
	//----------------------------------------------------------
	mux.Handle("POST", "/message/{id}/reply", handler.Wrapper(
		handler.Request{
			Handler:        reply.Create,
			Name:           "reply-create",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))
	// exempt contents are filtered
	mux.Handle("GET", "/message/{id}/reply", handler.Wrapper(
		handler.Request{
			Handler: reply.List,
			Name:    "reply-list",
			Metrics: metrics,
			Securer: models.MessageSecurer,
		},
	))

	//----------------------------------------------------------
	// Message Interaction
	//----------------------------------------------------------
	mux.Handle("POST", "/message/{id}/interaction/{type}/add", handler.Wrapper(
		handler.Request{
			Handler:        interaction.Add,
			Name:           "interactions-add",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))

	mux.Handle("POST", "/message/{id}/interaction/{type}/delete", handler.Wrapper(
		handler.Request{
			Handler:        interaction.Delete,
			Name:           "interactions-delete",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))

	// get all the interactions for message
	// exempt contents are filtered
	mux.Handle("GET", "/message/{id}/interaction/{type}", handler.Wrapper(
		handler.Request{
			Handler: interaction.List,
			Name:    "interactions-list-typed",
			Metrics: metrics,
			Securer: models.MessageSecurer,
		},
	))

	// Channel Operations
	//----------------------------------------------------------
	mux.Handle("POST", "/channel", handler.Wrapper(
		handler.Request{
			Handler:        channel.Create,
			Name:           "channel-create",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel", handler.Wrapper(
		handler.Request{
			Handler: channel.List,
			Name:    "channel-list",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/search", handler.Wrapper(
		handler.Request{
			Handler: channel.Search,
			Name:    "channel-search",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/name/{name}", handler.Wrapper(
		handler.Request{
			Handler: channel.ByName,
			Name:    "channel-get-byname",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	mux.Handle("GET", "/channel/checkparticipation", handler.Wrapper(
		handler.Request{
			Handler: channel.CheckParticipation,
			Name:    "channel-check-participation",
			Metrics: metrics,
			Securer: nil, // we dont need to secure this function
		},
	))

	// deprecated, here for socialworker
	mux.Handle("POST", "/channel/{id}", handler.Wrapper(
		handler.Request{
			Handler:        channel.Update,
			Name:           "channel-update-old",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/channel/{id}/update", handler.Wrapper(
		handler.Request{
			Handler:        channel.Update,
			Name:           "channel-update",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/channel/{id}/delete", handler.Wrapper(
		handler.Request{
			Handler:        channel.Delete,
			Name:           "channel-delete",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/{id}", handler.Wrapper(
		handler.Request{
			Handler: channel.Get,
			Name:    "channel-get",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// add a new messages to the channel
	mux.Handle("POST", "/channel/{id}/message", handler.Wrapper(
		handler.Request{
			Handler:        message.Create,
			Name:           "channel-message-create",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	mux.Handle("GET", "/channel/{id}/participants", handler.Wrapper(
		handler.Request{
			Handler: participant.List,
			Name:    "participant-list",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/channel/{id}/participants/add", handler.Wrapper(
		handler.Request{
			Handler:        participant.AddMulti,
			Name:           "participant-multi-add",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/channel/{id}/participants/remove", handler.Wrapper(
		handler.Request{
			Handler:        participant.RemoveMulti,
			Name:           "participant-multi-remove",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/channel/{id}/participant/{accountId}/presence", handler.Wrapper(
		handler.Request{
			Handler:        participant.UpdatePresence,
			Name:           "participant-presence-update",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.ChannelSecurer,
		},
	))

	// list messages of the channel
	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/channel/{id}/history", handler.Wrapper(
		handler.Request{
			Handler: messagelist.List,
			Name:    "channel-history-list",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// message count of the channel
	mux.Handle("GET", "/channel/{id}/history/count", handler.Wrapper(
		handler.Request{
			Handler: messagelist.Count,
			Name:    "channel-history-count",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// register an account
	mux.Handle("POST", "/account", handler.Wrapper(
		handler.Request{
			Handler:        account.Register,
			Name:           "account-create",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.MessageSecurer,
		},
	))

	mux.Handle("POST", "/account/{id}", handler.Wrapper(
		handler.Request{
			Handler: account.Update,
			Name:    "account-update",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	// added troll mode protection
	// list channels of the account
	mux.Handle("GET", "/account/{id}/channels", handler.Wrapper(
		handler.Request{
			Handler: account.ListChannels,
			Name:    "account-channel-list",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	mux.Handle("GET", "/account/{id}/channels/count", handler.Wrapper(
		handler.Request{
			Handler: account.ParticipatedChannelCount,
			Name:    "account-channel-list-count",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	// list posts of the account
	mux.Handle("GET", "/account/{id}/posts", handler.Wrapper(
		handler.Request{
			Handler: account.ListPosts,
			Name:    "account-post-list",
			Metrics: metrics,
			Securer: models.AccountSecurer,
		},
	))

	// follow the account
	mux.Handle("POST", "/account/{id}/follow", handler.Wrapper(
		handler.Request{
			Handler:        account.Follow,
			Name:           "account-follow",
			CollectMetrics: true,
			Metrics:        metrics,
			Securer:        models.AccountSecurer,
		},
	))

	// un-follow the account
	mux.Handle("POST", "/account/{id}/unfollow", handler.Wrapper(
		handler.Request{
			Handler:        account.Unfollow,
			Name:           "account-unfollow",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))

	// check ownership of an object
	mux.Handle("GET", "/account/{id}/owns", handler.Wrapper(
		handler.Request{
			Handler: account.CheckOwnership,
			Name:    "account-owns",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	// fetch profile feed
	// mux.Handle("GET", "/account/{id}/profile/feed", handler.Wrapper(
	//   handler.Request{
	//     Handler: account.ListProfileFeed,
	//     Name:    "list-profile-feed",
	//   },
	// ))

	// get pinning channel of the account
	mux.Handle("GET", "/activity/pin/channel", handler.Wrapper(
		handler.Request{
			Handler: activity.GetPinnedActivityChannel,
			Name:    "activity-pin-get-channel",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	// exempt contents are filtered
	// caching enabled
	mux.Handle("GET", "/activity/pin/list", handler.Wrapper(
		handler.Request{
			Handler: activity.List,
			Name:    "activity-pin-list-message",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	// pin a new status update
	mux.Handle("POST", "/activity/pin/add", handler.Wrapper(
		handler.Request{
			Handler:        activity.PinMessage,
			Name:           "activity-add-pinned-message",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))
	// unpin a status update
	mux.Handle("POST", "/activity/pin/remove", handler.Wrapper(
		handler.Request{
			Handler:        activity.UnpinMessage,
			Name:           "activity-remove-pinned-message",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))

	// @todo add tests
	mux.Handle("POST", "/activity/pin/glance", handler.Wrapper(
		handler.Request{
			Handler:        activity.Glance,
			Name:           "activity-pinned-message-glance",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))

	// get popular topics
	// exempt contents are filtered
	// TODO add caching
	mux.Handle("GET", "/popular/topics/{statisticName}", handler.Wrapper(
		handler.Request{
			Handler: popular.ListTopics,
			Name:    "list-popular-topics",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	// exempt contents are filtered
	// TODO add caching
	mux.Handle("GET", "/popular/posts/{channelName}", handler.Wrapper(
		handler.Request{
			Handler: popular.ListPosts,
			Name:    "list-popular-posts",
			Metrics: metrics,
			// Securer: models.ChannelSecurer,
		},
	))

	mux.Handle("POST", "/privatemessage/init", handler.Wrapper(
		handler.Request{
			Handler:        privatemessage.Init,
			Name:           "privatemessage-init",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))

	mux.Handle("POST", "/privatemessage/send", handler.Wrapper(
		handler.Request{
			Handler:        privatemessage.Send,
			Name:           "privatemessage-send",
			CollectMetrics: true,
			Metrics:        metrics,
			// Securer:        models.AccountSecurer,
		},
	))

	// exempt contents are filtered
	mux.Handle("GET", "/privatemessage/list", handler.Wrapper(
		handler.Request{
			Handler: privatemessage.List,
			Name:    "privatemessage-list",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	mux.Handle("GET", "/privatemessage/search", handler.Wrapper(
		handler.Request{
			Handler: privatemessage.Search,
			Name:    "privatemessage-search",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	mux.Handle("GET", "/privatemessage/count", handler.Wrapper(
		handler.Request{
			Handler: privatemessage.Count,
			Name:    "privatemessage-count",
			Metrics: metrics,
			// Securer: models.AccountSecurer,
		},
	))

	return mux
}

// to-do list
// get current account from context for future
// like client.connection.delegate
