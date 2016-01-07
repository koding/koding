kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


setFeedListItem = (id, feedItem) ->

  { SOCIAL_SHARE_LINK_CREATED } = actionTypes

  dispatch SOCIAL_SHARE_LINK_CREATED, { id, feedItem }


unsetFeedListItem = (id) ->

  { SOCIAL_SHARE_LINK_DELETED } = actionTypes

  dispatch SOCIAL_SHARE_LINK_DELETED, { id }


setActiveSocialShareLink = (id) ->

  { SET_ACTIVE_SOCIAL_SHARE_LINK_ID } = actionTypes

  dispatch SET_ACTIVE_SOCIAL_SHARE_LINK_ID, { id }


module.exports = {
  setFeedListItem
  unsetFeedListItem
  setActiveSocialShareLink
}
