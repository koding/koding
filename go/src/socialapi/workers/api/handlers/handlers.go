package handlers

import (
	"socialapi/models"
	"socialapi/workers/api/modules/account"
	"socialapi/workers/api/modules/activity"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/client"
	"socialapi/workers/api/modules/interaction"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"
	"socialapi/workers/api/modules/popular"
	"socialapi/workers/api/modules/privatechannel"
	"socialapi/workers/api/modules/reply"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {

	m.AddHandler(
		handler.Request{
			Handler:  client.Location,
			Name:     "client-location",
			Type:     handler.GetRequest,
			Endpoint: "/client/location",
		},
	)

	//----------------------------------------------------------
	// Message Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:  message.Update,
			Name:     models.REQUEST_NAME_MESSAGE_UPDATE,
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  message.Delete,
			Name:     models.REQUEST_NAME_MESSAGE_DELETE,
			Type:     handler.DeleteRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageDeleteSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.Get,
			Name:     models.REQUEST_NAME_MESSAGE_GET,
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}",
			Securer:  models.MessageReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.GetBySlug,
			Name:     "message-get-by-slug",
			Type:     handler.GetRequest,
			Endpoint: "/message/slug/{slug}",
			Securer:  models.MessageReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  message.GetWithRelated,
			Name:     "message-get-with-related",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/related",
			Securer:  models.MessageReadSecurer,
		},
	)

	//----------------------------------------------------------
	// Message Reply Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:  reply.Create,
			Name:     "reply-create",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/reply",
			Securer:  models.MessageSecurer,
		},
	)

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  reply.List,
			Name:     "reply-list",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/reply",
			Securer:  models.MessageReadSecurer,
		},
	)

	//----------------------------------------------------------
	// Message Interaction
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:  interaction.Add,
			Name:     "interactions-add",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/interaction/{type}/add",
			Securer:  models.InteractionSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  interaction.Delete,
			Name:     "interactions-delete",
			Type:     handler.PostRequest,
			Endpoint: "/message/{id}/interaction/{type}/delete",
			Securer:  models.InteractionSecurer,
		},
	)

	// get all the interactions for message
	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  interaction.List,
			Name:     "interactions-list-typed",
			Type:     handler.GetRequest,
			Endpoint: "/message/{id}/interaction/{type}",
			Securer:  models.InteractionReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  interaction.ListInteractedMessages,
			Name:     "interactions-list-liked",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/interaction/{type}",
			Securer:  models.InteractionReadSecurer,
		},
	)

	// Channel Operations
	//----------------------------------------------------------
	m.AddHandler(
		handler.Request{
			Handler:  channel.Create,
			Name:     "channel-create",
			Type:     handler.PostRequest,
			Endpoint: "/channel",
			Securer:  models.ChannelSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.List,
			Name:     "channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.Search,
			Name:     "channel-search",
			Type:     handler.GetRequest,
			Endpoint: "/channel/search",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.ByName,
			Name:     "channel-get-byname",
			Type:     handler.GetRequest,
			Endpoint: "/channel/name/{name}",
			Securer:  models.ChannelReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  channel.CheckParticipation,
			Name:     "channel-check-participation",
			Type:     handler.GetRequest,
			Endpoint: "/channel/checkparticipation",
			Securer:  models.ChannelReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  channel.Update,
			Name:     "channel-update",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/update",
			Securer:  models.ChannelSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  channel.Delete,
			Name:     "channel-delete",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/delete",
			Securer:  models.ChannelSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  channel.Get,
			Name:     "channel-get",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}",
			Securer:  models.ChannelReadSecurer,
		},
	)

	// add a new messages to the channel
	m.AddHandler(
		handler.Request{
			Handler:  message.Create,
			Name:     "channel-message-create",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/message",
			Securer:  models.MessageSecurer,
		},
	)

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  participant.List,
			Name:     "participant-list",
			Type:     handler.GetRequest,
			Endpoint: "/channel/{id}/participants",
			Securer:  models.ParticipantReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  participant.AddMulti,
			Name:     "participant-multi-add",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/add",
			Securer:  models.ParticipantMultiSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  participant.RemoveMulti,
			Name:     "participant-multi-remove",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/remove",
			Securer:  models.ParticipantMultiSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  participant.BlockMulti,
			Name:     "participant-multi-block",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/block",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  participant.UnblockMulti,
			Name:     "participant-multi-unblock",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participants/unblock",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  participant.UpdatePresence,
			Name:     "participant-presence-update",
			Type:     handler.PostRequest,
			Endpoint: "/channel/{id}/participant/{accountId}/presence",
			Securer:  models.ParticipantSecurer,
		},
	)

	// list messages of the channel
	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  messagelist.List,
			Name:     "channel-history-list",
			Endpoint: "/channel/{id}/history",
			Type:     handler.GetRequest,
			Securer:  models.MessageListReadSecurer,
		},
	)

	// message count of the channel
	m.AddHandler(
		handler.Request{
			Handler:  messagelist.Count,
			Name:     "channel-history-count",
			Endpoint: "/channel/{id}/history/count",
			Type:     handler.GetRequest,
			Securer:  models.MessageListReadSecurer,
		},
	)

	// register an account
	m.AddHandler(
		handler.Request{
			Handler:  account.Register,
			Name:     "account-create",
			Type:     handler.PostRequest,
			Endpoint: "/account",
			Securer:  models.AccountReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  account.Update,
			Name:     "account-update",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}",
			Securer:  models.AccountSecurer,
		},
	)

	// added troll mode protection
	// list channels of the account
	m.AddHandler(
		handler.Request{
			Handler:  account.ListChannels,
			Name:     "account-channel-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels",
			Securer:  models.AccountReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  account.ParticipatedChannelCount,
			Name:     "account-channel-list-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/channels/count",
			Securer:  models.AccountReadSecurer,
		},
	)

	// list posts of the account
	m.AddHandler(
		handler.Request{
			Handler:  account.ListPosts,
			Name:     "account-post-list",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts",
			Securer:  models.AccountReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  account.FetchPostCount,
			Name:     "account-post-count",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/posts/count",
		})

	// follow the account
	m.AddHandler(
		handler.Request{
			Handler:  account.Follow,
			Name:     "account-follow",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}/follow",
			Securer:  models.AccountSecurer,
		},
	)

	// un-follow the account
	m.AddHandler(
		handler.Request{
			Handler:  account.Unfollow,
			Name:     "account-unfollow",
			Type:     handler.PostRequest,
			Endpoint: "/account/{id}/unfollow",
			Securer:  models.AccountSecurer,
		},
	)

	// check ownership of an object
	m.AddHandler(
		handler.Request{
			Handler:  account.CheckOwnership,
			Name:     "account-owns",
			Type:     handler.GetRequest,
			Endpoint: "/account/{id}/owns",
			Securer:  models.AccountReadSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  account.GetAccountFromSession,
			Name:     "account-info",
			Type:     handler.GetRequest,
			Endpoint: "/account",
		},
	)

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
			// this is
			Securer: models.PinnedActivityReadSecurer,
		},
	)

	// exempt contents are filtered
	// caching enabled
	m.AddHandler(
		handler.Request{
			Handler:  activity.List,
			Name:     "activity-pin-list-message",
			Type:     handler.GetRequest,
			Endpoint: "/activity/pin/list",
			Securer:  models.PinnedActivityReadSecurer,
		},
	)

	// pin a new status update
	m.AddHandler(
		handler.Request{
			Handler:  activity.PinMessage,
			Name:     "activity-add-pinned-message",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/add",

			Securer: models.PinnedActivitySecurer,
		},
	)
	// unpin a status update
	m.AddHandler(
		handler.Request{
			Handler:  activity.UnpinMessage,
			Name:     "activity-remove-pinned-message",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/remove",
			Securer:  models.PinnedActivitySecurer,
		},
	)

	// @todo add tests
	m.AddHandler(
		handler.Request{
			Handler:  activity.Glance,
			Name:     "activity-pinned-message-glance",
			Type:     handler.PostRequest,
			Endpoint: "/activity/pin/glance",
			Securer:  models.PinnedActivitySecurer,
		},
	)

	// get popular topics
	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  popular.ListTopics,
			Name:     "list-popular-topics",
			Type:     handler.GetRequest,
			Endpoint: "/popular/topics/{statisticName}",
			// Securer: #no need for securer
		},
	)

	// exempt contents are filtered
	// TODO add caching
	m.AddHandler(
		handler.Request{
			Handler:  popular.ListPosts,
			Name:     "list-popular-posts",
			Type:     handler.GetRequest,
			Endpoint: "/popular/posts/{channelName}",
			// Securer: #no need for securer
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Init,
			Name:     "privatechannel-init",
			Type:     handler.PostRequest,
			Endpoint: "/privatechannel/init",
			Securer:  models.PrivateMessageSecurer,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Send,
			Name:     "privatechannel-send",
			Type:     handler.PostRequest,
			Endpoint: "/privatechannel/send",
			Securer:  models.PrivateMessageSecurer,
		},
	)

	// exempt contents are filtered
	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.List,
			Name:     "privatechannel-list",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/list",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Search,
			Name:     "privatechannel-search",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/search",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  privatechannel.Count,
			Name:     "privatechannel-count",
			Type:     handler.GetRequest,
			Endpoint: "/privatechannel/count",
		},
	)
}
