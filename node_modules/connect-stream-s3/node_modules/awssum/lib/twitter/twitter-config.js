// --------------------------------------------------------------------------------------------------------------------
//
// twitter-config.js - config for Twitter
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// requires
// none

// --------------------------------------------------------------------------------------------------------------------

// From: https://dev.twitter.com/docs/api
//
// Timelines:
//
// * https://dev.twitter.com/docs/api/1/get/statuses/home_timeline
// * https://dev.twitter.com/docs/api/1/get/statuses/mentions
// * https://dev.twitter.com/docs/api/1/get/statuses/retweeted_by_me
// * https://dev.twitter.com/docs/api/1/get/statuses/retweeted_to_me
// * https://dev.twitter.com/docs/api/1/get/statuses/retweets_of_me
// * https://dev.twitter.com/docs/api/1/get/statuses/user_timeline
// * https://dev.twitter.com/docs/api/1/get/statuses/retweeted_to_user
// * https://dev.twitter.com/docs/api/1/get/statuses/retweeted_by_user
//
// Tweets:
//
// * https://dev.twitter.com/docs/api/1/get/statuses/%3Aid/retweeted_by
// * https://dev.twitter.com/docs/api/1/get/statuses/%3Aid/retweeted_by/ids
// * https://dev.twitter.com/docs/api/1/get/statuses/retweets/%3Aid
// * https://dev.twitter.com/docs/api/1/get/statuses/show/%3Aid
// * https://dev.twitter.com/docs/api/1/post/statuses/destroy/%3Aid
// * https://dev.twitter.com/docs/api/1/post/statuses/retweet/%3Aid
// * https://dev.twitter.com/docs/api/1/post/statuses/update
// * https://dev.twitter.com/docs/api/1/post/statuses/update_with_media
// * https://dev.twitter.com/docs/api/1/get/statuses/oembed
//
// Search:
//
// * https://dev.twitter.com/docs/api/1/get/search
//
// Direct Messages:
//
// * https://dev.twitter.com/docs/api/1/get/direct_messages
// * https://dev.twitter.com/docs/api/1/get/direct_messages/sent
// * https://dev.twitter.com/docs/api/1/post/direct_messages/destroy/%3Aid
// * https://dev.twitter.com/docs/api/1/post/direct_messages/new
// * https://dev.twitter.com/docs/api/1/get/direct_messages/show/%3Aid
//
// Friends and Followers:
//
// * https://dev.twitter.com/docs/api/1/get/followers/ids
// * https://dev.twitter.com/docs/api/1/get/friends/ids
// * https://dev.twitter.com/docs/api/1/get/friendships/exists
// * https://dev.twitter.com/docs/api/1/get/friendships/incoming
// * https://dev.twitter.com/docs/api/1/get/friendships/outgoing
// * https://dev.twitter.com/docs/api/1/get/friendships/show
// * https://dev.twitter.com/docs/api/1/post/friendships/create
// * https://dev.twitter.com/docs/api/1/post/friendships/destroy
// * https://dev.twitter.com/docs/api/1/get/friendships/lookup
// * https://dev.twitter.com/docs/api/1/post/friendships/update
// * https://dev.twitter.com/docs/api/1/get/friendships/no_retweet_ids
//
// Users:
//
// * https://dev.twitter.com/docs/api/1/get/users/lookup
// * https://dev.twitter.com/docs/api/1/get/users/profile_image/%3Ascreen_name
// * https://dev.twitter.com/docs/api/1/get/users/search
// * https://dev.twitter.com/docs/api/1/get/users/show
// * https://dev.twitter.com/docs/api/1/get/users/contributees
// * https://dev.twitter.com/docs/api/1/get/users/contributors
//
// Suggested Users:
//
// * https://dev.twitter.com/docs/api/1/get/users/suggestions
// * https://dev.twitter.com/docs/api/1/get/users/suggestions/%3Aslug
// * https://dev.twitter.com/docs/api/1/get/users/suggestions/%3Aslug/members
//
// Favourites:
//
// * https://dev.twitter.com/docs/api/1/get/favorites
// * https://dev.twitter.com/docs/api/1/post/favorites/create/%3Aid
// * https://dev.twitter.com/docs/api/1/post/favorites/destroy/%3Aid
//
// Lists:
//
// * https://dev.twitter.com/docs/api/1/get/lists/all
// * https://dev.twitter.com/docs/api/1/get/lists/statuses
// * https://dev.twitter.com/docs/api/1/post/lists/members/destroy
// * https://dev.twitter.com/docs/api/1/get/lists/memberships
// * https://dev.twitter.com/docs/api/1/get/lists/subscribers
// * https://dev.twitter.com/docs/api/1/post/lists/subscribers/create
// * https://dev.twitter.com/docs/api/1/get/lists/subscribers/show
// * https://dev.twitter.com/docs/api/1/post/lists/subscribers/destroy
// * https://dev.twitter.com/docs/api/1/post/lists/members/create_all
// * https://dev.twitter.com/docs/api/1/get/lists/members/show
// * https://dev.twitter.com/docs/api/1/get/lists/members
// * https://dev.twitter.com/docs/api/1/post/lists/members/create
// * https://dev.twitter.com/docs/api/1/post/lists/destroy
// * https://dev.twitter.com/docs/api/1/post/lists/update
// * https://dev.twitter.com/docs/api/1/post/lists/create
// * https://dev.twitter.com/docs/api/1/get/lists
// * https://dev.twitter.com/docs/api/1/get/lists/show
// * https://dev.twitter.com/docs/api/1/get/lists/subscriptions
// * https://dev.twitter.com/docs/api/1/post/lists/members/destroy_all
//
// Accounts:
//
// * https://dev.twitter.com/docs/api/1/get/account/rate_limit_status
// * https://dev.twitter.com/docs/api/1/get/account/verify_credentials
// * https://dev.twitter.com/docs/api/1/post/account/end_session
// * https://dev.twitter.com/docs/api/1/post/account/update_profile
// * https://dev.twitter.com/docs/api/1/post/account/update_profile_background_image
// * https://dev.twitter.com/docs/api/1/post/account/update_profile_colors
// * https://dev.twitter.com/docs/api/1/post/account/update_profile_image
// * https://dev.twitter.com/docs/api/1/get/account/totals
// * https://dev.twitter.com/docs/api/1/get/account/settings
// * https://dev.twitter.com/docs/api/1/post/account/settings
//
// Notification:
//
// * https://dev.twitter.com/docs/api/1/post/notifications/follow
// * https://dev.twitter.com/docs/api/1/post/notifications/leave
//
// Saved Searches:
//
// * https://dev.twitter.com/docs/api/1/get/saved_searches
// * https://dev.twitter.com/docs/api/1/get/saved_searches/show/%3Aid
// * https://dev.twitter.com/docs/api/1/post/saved_searches/create
// * https://dev.twitter.com/docs/api/1/post/saved_searches/destroy/%3Aid
//
// Places and Geo:
//
// * https://dev.twitter.com/docs/api/1/get/geo/id/%3Aplace_id
// * https://dev.twitter.com/docs/api/1/get/geo/reverse_geocode
// * https://dev.twitter.com/docs/api/1/get/geo/search
// * https://dev.twitter.com/docs/api/1/get/geo/similar_places
// * https://dev.twitter.com/docs/api/1/post/geo/place
//
// Trends:
//
// * https://dev.twitter.com/docs/api/1/get/trends/%3Awoeid
// * https://dev.twitter.com/docs/api/1/get/trends/available
// * https://dev.twitter.com/docs/api/1/get/trends/daily
// * https://dev.twitter.com/docs/api/1/get/trends/weekly
//
// Block:
//
// * https://dev.twitter.com/docs/api/1/get/blocks/blocking
// * https://dev.twitter.com/docs/api/1/get/blocks/blocking/ids
// * https://dev.twitter.com/docs/api/1/get/blocks/exists
// * https://dev.twitter.com/docs/api/1/post/blocks/create
// * https://dev.twitter.com/docs/api/1/post/blocks/destroy
//
// Spam Reporting:
//
// * https://dev.twitter.com/docs/api/1/post/report_spam
//
// OAuth (already included in oauth.js):
//
// * https://dev.twitter.com/docs/api/1/get/oauth/authenticate
// * https://dev.twitter.com/docs/api/1/get/oauth/authorize
// * https://dev.twitter.com/docs/api/1/post/oauth/access_token
// * https://dev.twitter.com/docs/api/1/post/oauth/request_token
//
// Help:
//
// * https://dev.twitter.com/docs/api/1/get/help/test
// * https://dev.twitter.com/docs/api/1/get/help/configuration
// * https://dev.twitter.com/docs/api/1/get/help/languages
//
// Legal:
//
// * https://dev.twitter.com/docs/api/1/get/legal/privacy
// * https://dev.twitter.com/docs/api/1/get/legal/tos
//
// Deprecated:
//
// * 26 operations which aren't implemented in AwsSum!

// helper variables
var paramRequired   = { type : 'param',   required : false };
var paramOptional   = { type : 'param',   required : false };
var specialRequired = { type : 'special', required : false };

module.exports = {

    // Timelines

    'GetHomeTimeline' : {
        'path' : '/1/statuses/home_timeline.json',
        'args' : {
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_rts'         : paramOptional,
            'include_entities'    : paramOptional,
            'exclude_replies'     : paramOptional,
            'contributor_details' : paramOptional,
        },
    },

    'GetMentions' : {
        'path' : '/1/statuses/mentions.json',
        'args' : {
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_rts'         : paramOptional,
            'include_entities'    : paramOptional,
            'contributor_details' : paramOptional,
        },
    },

    GetRetweetedByMe : {
        'path' : '/1/statuses/retweeted_by_me.json',
        'args' : {
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_entities'    : paramOptional,
        },
    },

    GetRetweetedToMe : {
        'path' : '/1/statuses/retweeted_to_me.json',
        'args' : {
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_entities'    : paramOptional,
        },
    },

    GetRetweetsOfMe : {
        'path' : '/1/statuses/retweets_of_me.json',
        'args' : {
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_entities'    : paramOptional,
        },
    },

    GetUserTimeline : {
        'path' : '/1/statuses/user_timeline.json',
        'args' : {
            'user_id'             : paramOptional,
            'screen_name'         : paramOptional,
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_rts'         : paramOptional,
            'include_entities'    : paramOptional,
            'exclude_replies'     : paramOptional,
            'contributor_details' : paramOptional,
        },
    },

    GetRetweetedToUser : {
        'path' : '/1/statuses/retweeted_to_user.json',
        'args' : {
            'screen_name'         : paramOptional,
            'id'                  : paramOptional,
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_entities'    : paramOptional,
        },
    },

    GetRetweetedByUser : {
        'path' : '/1/statuses/retweeted_by_user.json',
        'args' : {
            'screen_name'         : paramOptional,
            'id'                  : paramOptional,
            'count'               : paramOptional,
            'since_id'            : paramOptional,
            'max_id'              : paramOptional,
            'page'                : paramOptional,
            'trim_user'           : paramOptional,
            'include_entities'    : paramOptional,
        },
    },

    // Tweets

    RetweetedBy : {
        'path' : function(options, args) { return '/1/statuses/' + args.id + '/retweeted_by.json'; },
        'args' : {
            'id'    : specialRequired,
            'count' : paramOptional,
            'page'  : paramOptional,
        },
    },

    RetweetedByIds : {
        'path' : function(options, args) { return '/1/statuses/' + args.id + '/retweeted_by/ids.json'; },
        'args' : {
            'id'            : specialRequired,
            'count'         : paramOptional,
            'page'          : paramOptional,
            'stringify_ids' : paramOptional,
        },
    },

    Retweets : {
        'path' : function(options, args) { return '/1/statuses/retweets/' + args.id + '.json'; },
        'args' : {
            'id'               : specialRequired,
            'count'            : paramOptional,
            'trim_user'        : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    Show : {
        'path' : function(options, args) { return '/1/statuses/show/' + args.id + '.json'; },
        'args' : {
            'id'                 : specialRequired,
            'trim_user'          : paramOptional,
            'include_entities'   : paramOptional,
            'include_my_retweet' : paramOptional,
        },
    },

    Destroy : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/statuses/destroy/' + args.id + '.json'; },
        'args' : {
            'id'                 : specialRequired,
            'include_entities'   : paramOptional,
            'trim_user'          : paramOptional,
        },
    },

    Retweet : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/statuses/retweet/' + args.id + '.json'; },
        'args' : {
            'id'                 : specialRequired,
            'include_entities'   : paramOptional,
            'trim_user'          : paramOptional,
        },
    },

    Update : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/statuses/update.json'; },
        'args' : {
            'status'                : paramRequired,
            'in_reply_to_status_id' : paramOptional,
            'lat'                   : paramOptional,
            'long'                  : paramOptional,
            'place_id'              : paramOptional,
            'display_coordinates'   : paramOptional,
            'trim_user'             : paramOptional,
            'include_entities'      : paramOptional,
        },
    },

    // UpdateWithMedia : {
    //     host   : 'upload.twitter.com', // for Media uploads
    //     'method' : 'POST',
    //     'path' : function(options, args) { return '/1/statuses/update_with_media.json'; },
    //     'args' : {
    //         'status'                : paramRequired
    //         'media'                 : paramOptional,
    //         'possibly_sensitive'    : paramOptional,
    //         'in_reply_to_status_id' : paramOptional,
    //         'lat'                   : paramOptional,
    //         'long'                  : paramOptional,
    //         'place_id'              : paramOptional,
    //         'display_coordinates'   : paramOptional,
    //     },
    // },

    OEmbed : {
        'path' : function(options, args) { return '/1/statuses/oembed.json'; },
        'args' : {
            'id'          : paramOptional,
            'url'         : paramOptional,
            'maxwidth'    : paramOptional,
            'hide_media'  : paramOptional,
            'hide_thread' : paramOptional,
            'omit_script' : paramOptional,
            'align'       : paramOptional,
            'related'     : paramOptional,
            'lang'        : paramOptional,
        },
    },

    // Search

    Search : {
        // request
        host : 'search.twitter.com',
        'path' : '/search.json',
        'args' : {
            'q'                : paramRequired,
            'callback'         : paramOptional,
            'geocode'          : paramOptional,
            'lang'             : paramOptional,
            'locale'           : paramOptional,
            'page'             : paramOptional,
            'result_type'      : paramOptional,
            'rrp'              : paramOptional,
            'show_user'        : paramOptional,
            'until'            : paramOptional,
            'since_id'         : paramOptional,
            'max_id'           : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    // Direct Messages

    DirectMessages : {
        // request
        'path' : '/1/direct_messages.json',
        'args' : {
            'since_id'         : paramOptional,
            'max_id'           : paramOptional,
            'count'            : paramOptional,
            'page'             : paramOptional,
            'include_entities' : paramOptional,
            'skip_status'      : paramOptional,
        },
    },

    DirectMessagesSent : {
        // request
        'path' : '/1/direct_messages/sent.json',
        'args' : {
            'since_id'         : paramOptional,
            'max_id'           : paramOptional,
            'count'            : paramOptional,
            'page'             : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    DirectMessageDestroy : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/direct_messages/destroy/' + args.id + '.json'; },
        'args' : {
            'id'                 : specialRequired,
            'include_entities'   : paramOptional,
        },
    },

    DirectMessagesNew : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/direct_messages/new.json'; },
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
            'text'        : paramRequired,
            'wrap_links'  : paramOptional,
        },
    },

    DirectMessagesShow : {
        'path' : function(options, args) { return '/1/direct_messages/show/' + args.id + '.json'; },
        'args' : {
            'id' : specialRequired,
        },
    },

    // Friends and Followers

    GetFollowers : {
        'path' : function(options, args) { return '/1/followers/' + args.id + '.json'; },
        'args' : {
            'user_id'       : paramOptional,
            'screen_name'   : paramOptional,
            'cursor'        : paramOptional,
            'stringify_ids' : paramOptional,
        },
    },

    GetFriends : {
        'path' : function(options, args) { return '/1/friends/ids.json'; },
        'args' : {
            'user_id'       : paramOptional,
            'screen_name'   : paramOptional,
            'cursor'        : paramOptional,
            'stringify_ids' : paramOptional,
        },
    },

    GetFriendshipsExists : {
        'path' : function(options, args) { return '/1/friendships/exists.json'; },
        'args' : {
            'user_id_a'     : paramOptional,
            'user_id_b'     : paramOptional,
            'screen_name_a' : paramOptional,
            'screen_name_b' : paramOptional,
        },
    },

    GetFriendshipsIncoming : {
        'path' : function(options, args) { return '/1/friendships/incoming.json'; },
        'args' : {
            'cursor'        : paramOptional,
            'stringify_ids' : paramOptional,
        },
    },

    GetFriendshipsOutgoing : {
        'path' : function(options, args) { return '/1/friendships/outgoing.json'; },
        'args' : {
            'cursor'        : paramOptional,
            'stringify_ids' : paramOptional,
        },
    },

    GetFriendshipsShow : {
        'path' : function(options, args) { return '/1/friendships/show.json'; },
        'args' : {
            'source_id'          : paramOptional,
            'source_screen_name' : paramOptional,
            'target_id'          : paramOptional,
            'target_screen_name' : paramOptional,
        },
    },

    FriendshipsCreate : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/friendships/create.json'; },
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
            'follow'      : paramOptional,
        },
    },

    FriendshipsDestroy : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/friendships/destroy.json'; },
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    FriendshipsLookup : {
        'path' : function(options, args) { return '/1/friendships/lookup.json'; },
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
        },
    },

    FriendshipsUpdate : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/friendships/update.json'; },
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
            'device'      : paramOptional,
            'retweets'    : paramOptional,
        },
    },

    GetFriendshipsNoRetweetIds : {
        'path' : function(options, args) { return '/1/friendships/no_retweet_ids.json'; },
        'args' : {
            'stringify_ids' : paramOptional,
        },
    },

    // Users

    GetUsersLookup : {
        'path' : function(options, args) { return '/1/users/lookup.json'; },
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    GetUsersProfileImage : {
        'path' : function(options, args) { return '/1/users/profile_image/' + args.screen_name; },
        'args' : {
            'screen_name' : specialRequired,
            'size'        : paramOptional,
        },
        // response
        'statusCode' : 302,
        'extractBody' : 'none',
    },

    GetUsersSearch : {
        // request
        'path' : '/1/users/search.json',
        'args' : {
            'q'                : paramRequired,
            'page'             : paramOptional,
            'per_page'         : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    GetUsersShow : {
        // request
        'path' : '/1/users/search.json',
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    GetUsersContributees : {
        // request
        'path' : '/1/users/contributees.json',
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'include_entities' : paramOptional,
            'skip_status'      : paramOptional,
        },
    },

    GetUsersContributors : {
        // request
        'path' : '/1/users/contributors.json',
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'include_entities' : paramOptional,
            'skip_status'      : paramOptional,
        },
    },

    // Suggested Users

    GetUsersSuggestions : {
        // request
        'path' : '/1/users/suggestions.json',
        'args' : {
            'lang' : paramOptional,
        },
    },

    GetUsersSuggestionsSlug : {
        // request
        'path' : function(options, args) { return '/1/users/suggestions/' + args.slug + '.json'; },
        'args' : {
            'slug' : specialRequired,
            'lang' : paramOptional,
        },
    },

    GetUsersSuggestionsSlugMembers : {
        // request
        'path' : function(options, args) { return '/1/users/suggestions/' + args.slug + 'members.json'; },
        'args' : {
            'slug' : specialRequired,
        },
    },

    // Favorites

    GetFavorites : {
        // request
        // Note: this is inconsistent with other requests, says something about 'id' being a change to the URL
        // but doesn't say what it is!
        'path' : '/1/users/favorites.json',
        'args' : {
            'user_id'          : paramOptional,
            'screen_name'      : paramOptional,
            'count'            : paramOptional,
            'since_id'         : paramOptional,
            'max_id'           : paramOptional,
            'page'             : paramOptional,
            'include_entities' : paramOptional,
        },
    },

    CreateFavorite : {
        // request
        'method' : 'POST',
        'path' : function(options, args) { return '/1/users/favorites/create/' + args.id + '.json'; },
        'args' : {
            'id'               : specialRequired,
            'include_entities' : paramOptional,
        },
    },

    DeleteFavorite : {
        // request
        'method' : 'POST',
        'path' : function(options, args) { return '/1/users/favorites/delete/' + args.id + '.json'; },
        'args' : {
            'id' : specialRequired,
        },
    },

    // Lists

    GetListsAll : {
        // request
        'path' : '/1/lists/all.json',
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
        },
    },

    GetListStatuses : {
        'path' : '/1/lists/statuses.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'since_id'          : paramOptional,
            'max_id'            : paramOptional,
            'per_page'          : paramOptional,
            'page'              : paramOptional,
            'include_entities'  : paramOptional,
            'include_rts'       : paramOptional,
        },
    },

    DestroyListMember : {
        'method' : 'POST',
        'path' : '/1/lists/members/destroy.json',
        'args' : {
            'list_id'           : paramOptional,
            'slug'              : paramOptional,
            'user_id'           : paramOptional,
            'screen_name'       : paramOptional,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    GetListMemberships : {
        'path' : '/1/lists/memberships.json',
        'args' : {
            'user_id'               : paramOptional,
            'screen_name'           : paramOptional,
            'cursor'                : paramOptional,
            'filter_to_owned_lists' : paramOptional,
        },
    },

    GetListSubscribers : {
        'path' : '/1/lists/memberships.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'cursor'            : paramOptional,
            'include_entities'  : paramOptional,
            'skip_status'       : paramOptional,
        },
    },

    CreateListSubscriber : {
        'method' : 'POST',
        'path' : '/1/lists/subscribers/create.json',
        'args' : {
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
        },
    },

    GetListSubscriber : {
        'path' : '/1/lists/subscribers/show.json',
        'args' : {
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'user_id'           : paramOptional,
            'screen_name'       : paramOptional,
            'include_entities'  : paramOptional,
            'skip_status'       : paramOptional,
        },
    },

    DestroyListSubscriber : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/subscribers/destroy.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    AddListMembers : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/members/create_all.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'user_id'           : paramOptional,
            'screen_name'       : paramOptional,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    ShowListMember : {
        // request
        'path' : '/1/lists/members/show.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'user_id'           : paramOptional,
            'screen_name'       : paramOptional,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'include_entities'  : paramOptional,
            'skip_status'       : paramOptional,
        },
    },

    GetListMembers : {
        // request
        'path' : '/1/lists/members.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'cursor'            : paramOptional,
            'include_entities'  : paramOptional,
            'skip_status'       : paramOptional,
        },
    },

    AddListMember : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/members/create.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'user_id'           : paramRequired,
            'screen_name'       : paramRequired,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    DeleteList : {
        // request
        'method' : 'DELETE',
        'path' : '/1/lists/destroy.json',
        'args' : {
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
            'list_id'           : paramOptional,
            'slug'              : paramOptional,
        },
    },

    UpdateList : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/update.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'name'              : paramOptional,
            'mode'              : paramOptional,
            'description'       : paramOptional,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    CreateList : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/create.json',
        'args' : {
            'name'        : paramRequired,
            'mode'        : paramOptional,
            'description' : paramOptional,
        },
    },

    GetLists : {
        // request
        'path' : '/1/lists.json',
        'args' : {
            'user_id'     : paramRequired,
            'screen_name' : paramRequired,
            'cursor'      : paramOptional,
        },
    },

    GetList : {
        // request
        'path' : '/1/lists/show.json',
        'args' : {
            'list_id' : paramRequired,
            'slug'    : paramRequired,
        },
    },

    GetListSubscriptions : {
        // request
        'path' : '/1/lists/subscriptions.json',
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
            'count'       : paramOptional,
            'cursor'      : paramOptional,
        },
    },

    DeleteListMembers : {
        // request
        'method' : 'POST',
        'path' : '/1/lists/members/destroy_all.json',
        'args' : {
            'list_id'           : paramRequired,
            'slug'              : paramRequired,
            'user_id'           : paramOptional,
            'screen_name'       : paramOptional,
            'owner_screen_name' : paramOptional,
            'owner_id'          : paramOptional,
        },
    },

    // Accounts - doesn't deal with entities, therefore named slightly differently

    AccountRateLimitStatus : {
        // request
        'path' : '/1/account/rate_limit_status.json',
        'args' : {},
    },

    AccountVerifyCredentials : {
        // request
        'path' : '/1/account/verify_credentials.json',
        'args' : {
            'include_entities'  : paramOptional,
            'skip_status'       : paramOptional,
        },
    },

    EndSession : {
        // request
        'method' : 'POST',
        'path' : '/1/account/end_session.json',
        'args' : {},
    },

    UpdateProfile : {
        // request
        'method' : 'POST',
        'path' : '/1/account/update_profile.json',
        'args' : {
            'name'             : paramOptional,
            'url'              : paramOptional,
            'location'         : paramOptional,
            'description'      : paramOptional,
            'include_entities' : paramOptional,
            'skip_status'      : paramOptional,
        },
    },

    // UpdateProfileBackgroundImage : {},

    UpdateProfileColors : {
        // request
        'method' : 'POST',
        'path' : '/1/account/update_profile_colors.json',
        'args' : {
            'profile_background_color'     : paramOptional,
            'profile_link_color'           : paramOptional,
            'profile_sidebar_border_color' : paramOptional,
            'profile_sidebar_fill_color'   : paramOptional,
            'profile_text_color'           : paramOptional,
            'skip_status'                  : paramOptional,
            'name'                         : paramOptional,
        },
    },

    // UpdateProfileImage : {},

    GetAccountTotals : {
        // request
        'path' : '/1/account/totals.json',
        'args' : {},
    },

    GetAccountSettings : {
        // request
        'path' : '/1/account/settings.json',
        'args' : {},
    },

    UpdateAccountSettings : {
        // request
        'method' : 'POST',
        'path' : '/1/account/settings.json',
        'args' : {
            'trend_location_woeid' : paramOptional,
            'sleep_time_enabled'   : paramOptional,
            'start_sleep_time'     : paramOptional,
            'end_sleep_time'       : paramOptional,
            'time_zone'            : paramOptional,
            'lang'                 : paramOptional,
        },
    },

    // Notification

    EnableNotifications : {
        // request
        'method' : 'POST',
        'path' : '/1/notifications/follow.json',
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
        },
    },

    DisableNotifications : {
        // request
        'method' : 'POST',
        'path' : '/1/notifications/leave.json',
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
        },
    },

    // Saved Searches

    GetSavedSearches : {
        'path' : '/1/saved_searches.json',
        'args' : {},
    },

    GetSavedSearch : {
        'path' : function(options, args) { return '/1/saved_searches/show/' + args.id + '.json'; },
        'args' : {
            'id' : specialRequired,
        },
    },

    CreateSavedSearch : {
        'method' : 'POST',
        'path' : '/1/saved_searches/create.json',
        'args' : {
            'query' : paramRequired,
        },
    },

    DestroySavedSearch : {
        'method' : 'POST',
        'path' : function(options, args) { return '/1/saved_searches/destroy/' + args.id + '.json'; },
        'args' : {
            'id' : specialRequired,
        },
    },

    // Places and Geo

    GetPlace : {
        'path' : function(options, args) { return '/1/geo/id/' + args.id + '.json'; },
        'args' : {
            'id' : specialRequired,
        },
    },

    ReverseGeocode : {
        'path' : '/1/geo/reverse_geocode.json',
        'args' : {
            'lat'         : paramRequired,
            'long'        : paramRequired,
            'accuracy'    : paramOptional,
            'granularity' : paramOptional,
            'max_results' : paramOptional,
            'callback'    : paramOptional,
        },
    },

    SearchGeocode : {
        'path' : '/1/geo/search.json',
        'args' : {
            'lat'              : paramOptional,
            'long'             : paramOptional,
            'query'            : paramOptional,
            'ip'               : paramOptional,
            'granularity'      : paramOptional,
            'accuracy'         : paramOptional,
            'max_results'      : paramOptional,
            'contained_within' : paramOptional,
            'street_address'   : paramOptional,
            'callback'         : paramOptional,
        },
    },

    LocateSimilarPlaces : {
        'path' : '/1/geo/similar_places.json',
        'args' : {
            'lat'              : paramRequired,
            'long'             : paramRequired,
            'name'             : paramOptional,
            'contained_within' : paramOptional,
            'street_address'   : paramOptional,
            'callback'         : paramOptional,
        },
    },

    CreateGeoPlace : {
        'method' : 'POST',
        'path' : '/1/geo/place.json',
        'args' : {
            'name'             : paramRequired,
            'contained_within' : paramRequired,
            'token'            : paramRequired,
            'lat'              : paramRequired,
            'long'             : paramRequired,
            'street_address'   : paramOptional,
            'callback'         : paramOptional,
        },
    },

    // Trends

    GetTrendsForWeoid : {
        'path' : function(options, args) { return '/1/trends/' + args.woeid + '.json'; },
        'args' : {
            'weoid'   : paramRequired,
            'exclude' : paramOptional,
        },
    },

    GetAvailableTrends : {
        'path' : '/1/trends/available',
        'args' : {
            'lat'  : paramOptional,
            'long' : paramOptional,
        },
    },

    GetDailyTrends : {
        'path' : '/1/trends/daily',
        'args' : {
            'date'    : paramOptional,
            'exclude' : paramOptional,
        },
    },

    GetWeeklyTrends : {
        'path' : '/1/trends/weekly',
        'args' : {
            'date'    : paramOptional,
            'exclude' : paramOptional,
        },
    },

    // Block

    GetBlocking : {
        // request
        'path' : '/1/blocks/blocking.json',
        'args' : {
            'page'             : paramOptional,
            'per_page'         : paramOptional,
            'include_entities' : paramOptional,
            'skip_status'      : paramOptional,
            'cursor'           : paramOptional,
        },
    },

    GetBlockingIds : {
        // request
        'path' : '/1/blocks/blocking/ids.json',
        'args' : {
            'stringify_ids' : paramOptional,
            'cursor'        : paramOptional,
        },
    },

    GetBlockExists : {
        // request
        'path' : '/1/blocks/exists.json',
        'args' : {
            'screen_name'      : paramOptional,
            'user_id'          : paramOptional,
            'include_entities' : paramOptional,
            'skip_Status'      : paramOptional,
        },
    },

    CreateBlock : {
        // request
        'method' : 'POST',
        'args' : {
            'screen_name'      : paramOptional,
            'user_id'          : paramOptional,
            'include_entities' : paramOptional,
            'skip_Status'      : paramOptional,
        },
    },

    DestroyBlock : {
        // request
        'method' : 'POST',
        'args' : {
            'screen_name'      : paramOptional,
            'user_id'          : paramOptional,
            'include_entities' : paramOptional,
            'skip_Status'      : paramOptional,
        },
    },

    // Spam Reporting

    ReportSpam : {
        'method' : 'POST',
        'path' : '/1/report_spam.json',
        'args' : {
            'user_id'     : paramOptional,
            'screen_name' : paramOptional,
        },
    },

    // OAuth
    // (should be done in the OAuth.js parent class already)

    // Help

    Test : {
        // request
        'path' : '/1/help/test.json',
        // response
        'extractBody' : 'string',
    },

    Configuration : {
        // request
        'path' : '/1/help/configuration.json',
    },

    Languages : {
        // request
        'path' : '/1/help/languages.json',
    },

    // Legal

    PrivacyPolicy : {
        // request
        'path' : '/1/legal/privacy.json',
    },

    TermsOfService : {
        // request
        'path' : '/1/legal/tos.json',
    },

    // Deprecated
    // (not implementing)

};

// --------------------------------------------------------------------------------------------------------------------
