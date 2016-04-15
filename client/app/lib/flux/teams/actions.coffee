$           = require 'jquery'
kd          = require 'kd'
async       = require 'async'
whoami      = require 'app/util/whoami'
actions     = require './actiontypes'
remote      = require('app/remote').getInstance()
toImmutable = require 'app/util/toImmutable'
getters     = require './getters'
Promise     = require 'bluebird'
immutable   = require 'immutable'
Tracker     = require 'app/util/tracker'
isKoding    = require 'app/util/isKoding'
isEmailValid = require 'app/util/isEmailValid'


loadTeam = ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  canEditGroup = groupsController.canEditGroup()
  reactor.dispatch actions.LOAD_TEAM_SUCCESS, team


updateTeam = (dataToUpdate) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  new Promise (resolve, reject) ->

    team.modify dataToUpdate, (err, result) ->
      message  = 'Team settings has been successfully updated.'

      return reject { message: 'Couldn\'t update team settings. Please try again' }  if err

      resolve { message }


updateInviteInput = (index, inputType, value) ->

  { reactor } = kd.singletons


  reactor.dispatch actions.SET_TEAM_INVITE_INPUT_VALUE, { index, inputType, value }


fetchMembers = (options = {}) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()
  reactor.dispatch actions.FETCH_TEAM_MEMBERS_BEGIN, { team }

  team.fetchMembersWithEmail {}, options, (err, users) ->
    reactor.dispatch actions.FETCH_TEAM_MEMBERS_SUCCESS, { users }


fetchMembersRole = ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()
  reactor.dispatch actions.FETCH_TEAM_MEMBERS_ROLES_BEGIN, { team }

  myId = whoami().getId()
  teamMemberIds = reactor.evaluate getters.TeamMembersIdStore

  ids = teamMemberIds.toArray()
  ids.push myId

  team.fetchUserRoles ids, (err, roles) ->
    reactor.dispatch actions.FETCH_TEAM_MEMBERS_ROLES_SUCCESS, roles


inviteMembers = (inviteInputs) ->

  { reactor } = kd.singletons
  reactor.dispatch actions.RESET_TEAM_INVITES
  invites = []
  admins  = []

  new Promise (resolve, reject) ->

    whoami().fetchEmail (err, ownEmail) =>

      inviteInputs.forEach (inviteInput) ->

        email = inviteInput.get('email').trim()
        return  unless email

        validEmail = isEmailValid email

        if email.toLowerCase() is ownEmail

          return reject { message: 'You can not invite yourself!'}

        if email and not validEmail

          return reject { message: 'That doesn\'t seem like a valid email address.'}

        invites.push invite = inviteInput.toJS()
        admins.push invite.email  if invite.role is 'admin'

      Tracker.track Tracker.TEAMS_INVITED_TEAMMEMBERS, {
        invitesCount : invites.length
        adminsCount  : admins.length
      }

      if admins.length
        resolve { invites, admins }
      else
        resolve { invites }


loadPendingInvites = (invites) ->

  { reactor } = kd.singletons

  options = {}

  new Promise (resolve, reject) ->

    remote.api.JInvitation.some { status: 'pending' }, options, (err, pendings) ->
      if err
        reject err
      invites = invites.map (invite) -> invite.email
      pendingInvitations = pendings.reduce (pendingInvitations, invitation) ->
        index = pendingInvitations.size
        return pendingInvitations.set index, toImmutable(invitation)  if invitation.email in invites
        return pendingInvitations
      , immutable.Map()

      resolve { pendingInvitations }


sendInvitations = (invites, pendingInvites) ->

  new Promise (resolve, reject) ->

    remote.api.JInvitation.create { invitations: invites }, (err) =>
      if err
        return reject { title }

      title = "Invitation is sent to <strong>#{invites.first.email}</strong>"

      if invites.length > 1 or pendingInvites?.size
        title = 'All invitations are sent.'

      resolve { title }

      Tracker.track Tracker.TEAMS_SENT_INVITATION for invite in invites


resendInvitations = (pendingInvitations, newInvitations) ->

  new Promise (resolve, reject) ->
    title    = 'Invitation is resent.'
    title    = 'Invitations are resent.'  if pendingInvitations.size > 1

    queue = pendingInvitations.toArray().map (invite) -> (next) ->

      remote.api.JInvitation.sendInvitationByCode invite.get('code'), (err) ->
        if err
        then next err
        else next()

    async.series queue, (err) ->

      unless newInvitations.length
        title  = "Invitation is resent to <strong>#{pendingInvitations.get(0).get('email')}</strong>"
        title  = 'All invitations are resent.'  if pendingInvitations.size > 1
        resolve { title }


getNewInvitations = (invites, pendingInvitations) ->

  new Promise (resolve, reject) ->
    pendingEmails=[]

    pendingInvitations.map (invite) ->
      pendingEmails.push invite.get('email')

    newInvitations = (invite for invite, i in invites when invite.email not in pendingEmails)
    resolve { newInvitations }


setSearchInputValue = (value) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.SET_SEARCH_INPUT_VALUE, value


handleRoleChange = (newRole, member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  newRoles = [newRole]
  if newRole is 'owner'
    newRoles.push 'admin'

  memberId = member.get '_id'

  team.changeMemberRoles memberId, newRoles, (err, response) ->
    unless err
      team.fetchUserRoles [memberId], (err, roles) ->
        unless err
          roles = (role.as for role in roles)
          member = member.set 'role', roles   #send all roles for that user but we save only one
          reactor.dispatch actions.UPDATE_TEAM_MEMBER, member


handleKickMember = (member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  return  if isKoding team

  memberId = member.get '_id'

  team.kickMember memberId, (err) ->
    # handle, what if there is error
    unless err
      reactor.dispatch actions.DELETE_TEAM_MEMBER, memberId



module.exports = {
  loadTeam
  updateTeam
  updateInviteInput
  inviteMembers
  fetchMembers
  fetchMembersRole
  loadPendingInvites
  getNewInvitations
  sendInvitations
  resendInvitations
  setSearchInputValue
  handleRoleChange
  handleKickMember
}
