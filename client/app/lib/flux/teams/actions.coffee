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
s3upload = require 'app/util/s3upload'


loadTeam = ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  reactor.dispatch actions.LOAD_TEAM_SUCCESS, { team }


updateTeam = (dataToUpdate) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  new Promise (resolve, reject) ->

    team.modify dataToUpdate, (err, result) ->
      message  = 'Team settings has been successfully updated.'

      return reject { message: 'Couldn\'t update team settings. Please try again' }  if err

      resolve { message }


updateInvitationInputValue = (index, inputType, value) ->

  { reactor } = kd.singletons


  reactor.dispatch actions.SET_TEAM_INVITE_INPUT_VALUE, { index, inputType, value }


fetchMembers = (options = {}) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()
  reactor.dispatch actions.LOAD_TEAM_MEMBERS_BEGIN, { team }

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


loadPendingInvitations = ->

  { reactor } = kd.singletons

  options = {}

  reactor.dispatch actions.LOAD_PENDING_INVITATION_BEGIN

  remote.api.JInvitation.some { status: 'pending' }, options, (err, invitations) ->

    reactor.dispatch actions.LOAD_PENDING_INVITATION_FAIL  if err
    reactor.dispatch actions.LOAD_PENDING_INVITATION_SUCCESS, { invitations }


sendInvitations = ->

  { reactor } = kd.singletons
  newInvitations = reactor.evaluate getters.newInvitations
  invitations = newInvitations
    .map (i) -> i.toJS()
    .toArray()
  pendingInvitations = reactor.evaluate getters.pendingInvitations

  new Promise (resolve, reject) ->

    remote.api.JInvitation.create { invitations: invitations }, (err) ->
      if err
        return reject { title }

      title = "Invitation is sent to <strong>#{invitations[0].email}</strong>"

      if invitations.length > 1 or pendingInvites?.size
        title = 'All invitations are sent.'

      Tracker.track Tracker.TEAMS_SENT_INVITATION  for invite in invitations

      reactor.dispatch actions.RESET_TEAM_INVITES
      resolve { title }


resendInvitations = ->

  { reactor } = kd.singletons

  newInvitations = reactor.evaluate getters.newInvitations

  resendInvitations = reactor.evaluate getters.resendInvitations
  resendInvitations = resendInvitations.toArray()

  new Promise (resolve, reject) ->
    title    = 'Invitation is resent.'
    title    = 'Invitations are resent.'  if resendInvitations.size > 1
    queue = resendInvitations.map (invite) -> (next) ->
      remote.api.JInvitation.sendInvitationByCode invite.get('code'), (err) ->
        if err
          next err
          reject { err }
        else next()

    async.series queue, (err) ->
      # send invitations if there is new
      if newInvitations.size
        sendInvitations().then ({ title }) ->
          title = 'All invitations are sent'
          resolve { title }
        .catch ({ title }) ->
          reject { title }
      else
        newInvitations.size
        title  = "Invitation is resent to <strong>#{resendInvitations[0].get('email')}</strong>"
        title  = 'All invitations are resent.'  if resendInvitations.size > 1
        resolve { title }

      reactor.dispatch actions.RESET_TEAM_INVITES


setSearchInputValue = (newValue) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.SET_SEARCH_INPUT_VALUE, { newValue }


handleRoleChange = (account, newRole) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  newRoles = [newRole]
  if newRole is 'owner'
    newRoles.push 'admin'

  accountId = account.get '_id'

  team.changeMemberRoles accountId, newRoles, (err, response) ->
    unless err
      team.fetchUserRoles [accountId], (err, roles) ->
        unless err
          roles = (role.as for role in roles)
          account = account.set 'role', roles   #send all roles for that user but we save only one
          reactor.dispatch actions.UPDATE_TEAM_MEMBER, { account }


handleKickMember = (member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  return  if isKoding team

  memberId = member.get '_id'

  team.kickMember memberId, (err) ->
    # handle, what if there is error
    unless err
      reactor.dispatch actions.DELETE_TEAM_MEMBER, memberId
      reactor.dispatch actions.SAVE_DISABLED_TEAM_MEMBER, { member }


uploads3 = ({ name, content, mimeType }) ->

  timeout = 3e4
  new Promise (resolve, reject) ->
    return reject {} unless name or content or mimeType
    s3upload { name, content, mimeType, timeout }, (err, url) ->
      if err then reject { err } else resolve { url }


module.exports = {
  loadTeam
  updateTeam
  updateInvitationInputValue
  fetchMembers
  fetchMembersRole
  loadPendingInvitations
  sendInvitations
  resendInvitations
  setSearchInputValue
  handleRoleChange
  handleKickMember
  uploads3
}
