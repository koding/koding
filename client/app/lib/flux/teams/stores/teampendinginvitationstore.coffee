KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamPendingInvitationStore extends KodingFluxStore

  @getterPath = 'TeamPendingInvitationStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_PENDING_INVITATION, @load


  load: (oldPendingInvitations, pendingInvitations) -> pendingInvitations
