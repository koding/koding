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
    @on actions.REMOVE_PENDING_INVITATION, @removePendingInvitation
    @on actions.REMOVE_PENDING_INVITATION_BY_ID, @removePendingInvitationById


  removePendingInvitationById: (invitations, { id }) ->

    invitations.delete id


  removePendingInvitation: (invitations, { email }) ->

    id = null
    invitations.forEach (invitation) ->
      if invitation.get('email') is email
        id = invitation.get('_id')

    invitations = invitations.delete id


  deleteInvitation: (pendingInvitations, { account }) ->

    pendingInvitations.delete account.get('_id')


  load: (pendingInvitations, { invitations }) ->

    pendingInvitations.withMutations (pendingInvitations) ->
      invitations.forEach (invitation) ->
        pendingInvitations.set invitation._id, toImmutable invitation
