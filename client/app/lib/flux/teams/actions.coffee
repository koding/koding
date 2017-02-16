$           = require 'jquery'
kd          = require 'kd'
async       = require 'async'
whoami      = require 'app/util/whoami'
actions     = require './actiontypes'
remote      = require 'app/remote'
toImmutable = require 'app/util/toImmutable'
getters     = require './getters'
Promise     = require 'bluebird'
immutable   = require 'immutable'
Tracker     = require 'app/util/tracker'
isEmailValid = require 'app/util/isEmailValid'
s3upload = require 'app/util/s3upload'
kookies = require 'kookies'
Tracker = require 'app/util/tracker'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
KodingKontrol = require 'app/kite/kodingkontrol'
globals = require 'globals'
showError = require 'app/util/showError'
DeleteTeamOverlay = require 'app/components/deleteteamoverlay'
verifyPassword = require 'app/util/verifyPassword'

loadTeam = ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  reactor.dispatch actions.LOAD_TEAM_SUCCESS, { team }


updateTeam = (dataToUpdate) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()
  if dataToUpdate.customize
    logo = dataToUpdate.customize?.logo
    groupsController.emit 'TEAM_LOGO_CHANGED', logo

  new Promise (resolve, reject) ->

    team.modify dataToUpdate, (err, result) ->
      message  = 'Team settings has been successfully updated.'

      return reject { message: 'Couldn\'t update team settings. Please try again' }  if err

      reactor.dispatch actions.UPDATE_TEAM_SUCCESS, { dataToUpdate }
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
    fetchMembersRole users


fetchMembersRole = (users) ->

  { groupsController, reactor } = kd.singletons

  team = groupsController.getCurrentGroup()

  reactor.dispatch actions.ALL_USERS_LOADED  if users.length < 10

  myId = whoami().getId()
  ids = users.map (user) -> user._id

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
        return reject { err }

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


handlePendingInvitationUpdate = (account, action) ->

  { reactor } = kd.singletons

  if action is 'revoke'
    remote.api.JInvitation.revokeInvitation account, (err) ->

      title = 'You are not authorized to revoke this invite.'

      return new kd.NotificationView { title, duration: 5000 }  if err

      reactor.dispatch actions.DELETE_PENDING_INVITATION_SUCCESS, { account }

  else if action is 'resend'
    remote.api.JInvitation.sendInvitationByCode account.get('code'), (err) ->

      title = 'Invitation is resent.'
      duration = 5000
      if err
        title = 'Unable to resend the invitation. Please try again.'

      return new kd.NotificationView { title, duration }


handleKickMember = (member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

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


loadDisabledUsers = ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  team.fetchBlockedAccountsWithEmail (err, members) ->
    reactor.dispatch actions.LOAD_DISABLED_MEMBERS, { members }  unless err


handleDisabledUser = (member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  memberId = member.get '_id'
  options =
    id: memberId
    removeUserFromTeam: no

  team.unblockMember options, (err) ->
    unless err
      fetchMembers().then (members) ->
        fetchMembersRole members
        reactor.dispatch actions.REMOVE_ENABLED_MEMBER, { memberId }

  .catch (err) -> 'error occurred while unblocking member'


handlePermanentlyDeleteMember = (member) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  memberId = member.get '_id'
  options =
    id: memberId
    removeUserFromTeam: yes

  team.unblockMember options, (err) ->
    reactor.dispatch actions.REMOVE_ENABLED_MEMBER, { memberId }


leaveTeam = (partial) ->

  new Promise (resolve, reject) ->
    new VerifyPasswordModal 'Confirm', partial, (currentPassword) ->
      verifyPassword currentPassword, (err) ->
        return reject err  if err

        { groupsController, reactor } = kd.singletons
        team = groupsController.getCurrentGroup()

        team.leave { password: currentPassword }, (err) ->
          if err
            return new kd.NotificationView { title : err.message }

          Tracker.track Tracker.USER_LEFT_TEAM
          kookies.expire 'clientId'
          global.location.replace '/'


deleteTeam = (partial) ->

  new Promise (resolve, reject) ->
    new VerifyPasswordModal 'Confirm', partial, (currentPassword) ->

      whoami().fetchEmail (err, email) ->
        options = { password: currentPassword, email }
        remote.api.JUser.verifyPassword options, (err, confirmed) ->

          return reject err.message  if err
          return reject 'Current password cannot be confirmed'  unless confirmed

          # show delete team overlay
          new DeleteTeamOverlay()

          { groupsController, reactor } = kd.singletons
          team = groupsController.getCurrentGroup()

          team.destroy currentPassword, (err) ->
            reject err  if err
            resolve()



fetchApiTokens = ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()
  team.fetchApiTokens (err, apiTokens)  ->

    reactor.dispatch actions.FETCH_API_TOKENS_SUCCESS, { apiTokens }  unless err


deleteApiToken = (apiTokenId) ->

  { reactor } = kd.singletons
  reactor.dispatch actions.DELETE_API_TOKEN_SUCCESS, { apiTokenId }


addApiToken = ->

  { reactor } = kd.singletons
  remote.api.JApiToken.create (err, apiToken) ->

    return showError err  if err

    reactor.dispatch actions.ADD_API_TOKEN_SUCCESS, { apiToken }


disableApiTokens = (state) ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()

  team.modify { isApiEnabled : state }, (err) ->

    return showError err  if err

    reactor.dispatch actions.SET_API_ACCESS_STATE, { state }


fetchCurrentStateOfApiAccess = ->

  { groupsController, reactor } = kd.singletons
  team = groupsController.getCurrentGroup()
  state = team.isApiEnabled is yes
  reactor.dispatch actions.SET_API_ACCESS_STATE, { state }


loadOtaToken = ->

  { reactor } = kd.singletons
  whoami().fetchOtaToken (err, token) ->

    cmd = if err
      "<a href='#'>Failed to generate your command, click to try again!</a>"
    else
      if globals.config.environment in ['dev', 'default', 'sandbox']
        "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
      else "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

    reactor.dispatch actions.LOAD_OTA_TOKEN_SUCCESS, { cmd }



module.exports = {
  loadTeam
  leaveTeam
  deleteTeam
  updateTeam
  updateInvitationInputValue
  fetchMembers
  fetchMembersRole
  loadPendingInvitations
  sendInvitations
  resendInvitations
  setSearchInputValue
  handleRoleChange
  handlePendingInvitationUpdate
  handleKickMember
  uploads3
  loadDisabledUsers
  handleDisabledUser
  handlePermanentlyDeleteMember
  fetchApiTokens
  deleteApiToken
  addApiToken
  disableApiTokens
  fetchCurrentStateOfApiAccess
  loadOtaToken
}
