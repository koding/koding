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
	"socialapi/workers/api/modules/privatechannel"
	"socialapi/workers/api/modules/reply"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	//----------------------------------------------------------
	// Message Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:        message.Update,
			Name:           "message-update",
			Type:           handler.PostRequest,
			Endpoint:       "/message/{id}",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        message.Delete,
			Name:           "message-delete",
			Type:           handler.DeleteRequest,
			Endpoint:       "/message/{id}",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.Get,
			Name:     "message-get",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.GetBySlug,
			Name:     "message-get-by-slug",
			Type:     handler.GetRequest,
			Endpoint: "/message/slug/{slug}",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.GetWithRelated,
			Name:     "message-get-with-related",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/related",
			Metrics:  metric,
		})

	//----------------------------------------------------------
	// Message Reply Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:        reply.Create,
			Name:           "reply-create",
			Type:           handler.PostRequest,
			Endpoint:       "/message/{id}/reply",
			CollectMetrics: true,
			Metrics:        metric,
		})
	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  reply.List,
			Name:     "reply-list",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/reply",
			Metrics:  metric,
		})

	//----------------------------------------------------------
	// Message Interaction
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:        interaction.Add,
			Name:           "interactions-add",
			Type:           handler.PostRequest,
			Endpoint:       "/message/{id}/interaction/{type}/add",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        interaction.Delete,
			Name:           "interactions-delete",
			Type:           handler.PostRequest,
			Endpoint:       "/message/{id}/interaction/{type}/delete",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// get all the interactions for message
	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  interaction.List,
			Name:     "interactions-list-typed",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/interaction/{type}",
			Metrics:  metric,
		})

	// Channel Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:        channel.Create,
			Name:           "channel-create",
			Type:           handler.PostRequest,
			Endpoint:       "/channel",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.List,
			Name:     "channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.Search,
			Name:     "channel-search",
			Type:     handler.GetRequest,
			Endpoint: "/channel/search",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.ByName,
			Name:     "channel-get-byname",
			Type:     handler.GetRequest,
			Endpoint: "/channel/name/{name}",
			Metrics:  metric,
		})
	m.AddHandler(
		handler.Request{
			Handler:  channel.CheckParticipation,
			Name:     "channel-check-participation",
			Type:     handler.GetRequest,
			Endpoint: "/channel/checkparticipation",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        channel.Update,
			Name:           "channel-update",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/update",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        channel.Delete,
			Name:           "channel-delete",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/delete",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.Get,
			Name:     "channel-get",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}",
			Metrics:  metric,
		})

	// add a new messages to the channel
	m.AddHandler(
		handler.Request{
			Handler:        message.Create,
			Name:           "channel-message-create",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/message",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  participant.List,
			Name:     "participant-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}/participants",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        participant.AddMulti,
			Name:           "participant-multi-add",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/participants/add",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        participant.RemoveMulti,
			Name:           "participant-multi-remove",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/participants/remove",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        participant.BlockMulti,
			Name:           "participant-multi-block",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/participants/block",
			CollectMetrics: true,
			Metrics:        metric,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:        participant.UnblockMulti,
			Name:           "participant-multi-unblock",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/participants/unblock",
			CollectMetrics: true,
			Metrics:        metric,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:        participant.UpdatePresence,
			Name:           "participant-presence-update",
			Type:           handler.PostRequest,
			Endpoint:       "/channel/{id}/participant/{accountId}/presence",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// list messages of the channel
	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  messagelist.List,
			Name:     "channel-history-list",
			Endpoint: "/channel/{id}/history",
			Type:     handler.GetRequest,
			Metrics:  metric,
		})

	// message count of the channel
	m.AddHandler(
		handler.Request{
			Handler:  messagelist.Count,
			Name:     "channel-history-count",
			Endpoint: "/channel/{id}/history/count",
			Type:     handler.GetRequest,
			Metrics:  metric,
		})

	// register an account
	m.AddHandler(
		handler.Request{
			Handler:        account.Register,
			Name:           "account-create",
			Type:           handler.PostRequest,
			Endpoint:       "/account",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  account.Update,
			Name:     "account-update",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}",
			Metrics:  metric,
		})

	// added troll mode protection
	// list channels of the account
	m.AddHandler(
		handler.Request{
			Handler:  account.ListChannels,
			Name:     "account-channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  account.ParticipatedChannelCount,
			Name:     "account-channel-list-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels/count",
			Metrics:  metric,
		})

	// list posts of the account
	m.AddHandler(
		handler.Request{
			Handler:  account.ListPosts,
			Name:     "account-post-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  account.FetchPostCount,
			Name:     "account-post-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts/count",
			Metrics:  metric,
		})

	// follow the account
	m.AddHandler(
		handler.Request{
			Handler:        account.Follow,
			Name:           "account-follow",
			Type:           handler.PostRequest,
			Endpoint:       "/account/{id}/follow",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// un-follow the account
	m.AddHandler(
		handler.Request{
			Handler:        account.Unfollow,
			Name:           "account-unfollow",
			Type:           handler.PostRequest,
			Endpoint:       "/account/{id}/unfollow",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// check ownership of an object
	m.AddHandler(
		handler.Request{
			Handler:  account.CheckOwnership,
			Name:     "account-owns",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/owns",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  account.GetAccountFromSession,
			Name:     "account-info",
			Type:     handler.GetRequest,
			Endpoint: "/account",
			Metrics:  metric,
		})

	// fetch profile feed
	// m.AddHandler("GET", "/account/{id}/profile/feed"
	//   handler.Request{
	//     Handler: account.ListProfileFeed,
	//     Name:    "list-profile-feed",
	//   },
	// )

	// get pinning channel of the account
	m.AddHandler(
		handler.Request{
			Handler:  activity.GetPinnedActivityChannel,
			Name:     "activity-pin-get-channel",
			Type:     handler.GetRequest,
			Endpoint: "/activity/pin/channel",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  activity.List,
			Name:     "activity-pin-list-message",
			Type:     handler.GetRequest,
			Endpoint: "/activity/pin/list",
			Metrics:  metric,
		})

	// pin a new status update
	m.AddHandler(
		handler.Request{
			Handler:        activity.PinMessage,
			Name:           "activity-add-pinned-message",
			Type:           handler.PostRequest,
			Endpoint:       "/activity/pin/add",
			CollectMetrics: true,
			Metrics:        metric,
		})
	// unpin a status update
	m.AddHandler(
		handler.Request{
			Handler:        activity.UnpinMessage,
			Name:           "activity-remove-pinned-message",
			Type:           handler.PostRequest,
			Endpoint:       "/activity/pin/remove",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// @todo add tests
	m.AddHandler(
		handler.Request{
			Handler:        activity.Glance,
			Name:           "activity-pinned-message-glance",
			Type:           handler.PostRequest,
			Endpoint:       "/activity/pin/glance",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// get popular topics
	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  popular.ListTopics,
			Name:     "list-popular-topics",
			Type:     handler.GetRequest,
			Endpoint: "/popular/topics/{statisticName}",
			Metrics:  metric,
		})

	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  popular.ListPosts,
			Name:     "list-popular-posts",
			Type:     handler.GetRequest,
			Endpoint: "/popular/posts/{channelName}",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        privatechannel.Init,
			Name:           "privatechannel-init",
			Type:           handler.PostRequest,
			Endpoint:       "/privatechannel/init",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        privatechannel.Send,
			Name:           "privatechannel-send",
			Type:           handler.PostRequest,
			Endpoint:       "/privatechannel/send",
			CollectMetrics: true,
			Metrics:        metric,
		})

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.List,
			Name:     "privatechannel-list",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/list",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Search,
			Name:     "privatechannel-search",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/search",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Count,
			Name:     "privatechannel-count",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/count",
			Metrics:  metric,
		})
}
