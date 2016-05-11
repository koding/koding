KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamInvitationStore extends KodingFluxStore

  @getterPath = 'TeamInvitationStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_PENDING_INVITATION_SUCCESS, @load
    @on actions.DELETE_PENDING_INVITATION_SUCCESS, @deleteInvitation


  deleteInvitation: (pendingInvitations, { account }) ->

    pendingInvitations.delete account.get('_id')


  load: (pendingInvitations, { invitations }) ->

    pendingInvitations.withMutations (pendingInvitations) ->
      invitations.forEach (invitation) ->
        pendingInvitations.set invitation._id, toImmutable invitation
