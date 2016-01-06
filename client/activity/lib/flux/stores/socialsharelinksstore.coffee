KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
actions         = require '../actions/actiontypes'

module.exports = class SocialShareLinksStore extends KodingFluxStore

  @getterPath = 'SocialShareLinksStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SOCIAL_SHARE_LINK_CREATED, @setItem
    @on actions.SOCIAL_SHARE_LINK_DELETED, @unsetItem


  setItem: (items, { id, feedItem }) ->

    items.set id, feedItem


  unsetItem: (items, { id }) ->

    items.remove id

