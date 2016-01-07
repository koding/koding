actions         = require '../actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

module.exports = class ActiveSocialShareLinkIdStore extends KodingFluxStore

  @getterPath = 'ActiveSocialShareLinkIdStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_ACTIVE_SOCIAL_SHARE_LINK_ID, @setActiveLinkId


  setActiveLinkId: (activeId, { id }) ->

    return id  if activeId isnt id
    return null
