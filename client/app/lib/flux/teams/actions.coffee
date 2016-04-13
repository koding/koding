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


validateEmail = (email) ->
  emailPattern = /// ^ #begin of line
   ([\w.-]+)         #one or more letters, numbers, _ . or -
   @                 #followed by an @ sign
   ([\w.-]+)         #then one or more letters, numbers, _ . or -
   \.                #followed by a period
   ([a-zA-Z.]{2,6})  #followed by 2 to 6 letters or periods
   $ ///i            #end of line and ignore case

  return emailPattern.test email


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
        console.log 'validateEmail', validateEmail email
        validatedEmail = validateEmail email

        if email.toLowerCase() is ownEmail

          return resolve { message: 'You can not invite yourself!'}

        if email and not validatedEmail

          return resolve { message: 'That doesn\'t seem like a valid email address.'}

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


getNewInvitations = (invites, pendingInvitations) ->
  new Promise (resolve, reject) ->
    pendingEmails=[]

    pendingInvitations.map (invite) ->
      pendingEmails.push invite.get('email')

    newInvitations = (invite for invite, i in invites when invite.email not in pendingEmails)
    resolve { newInvitations }



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

  ids = []
  ids.push myId

  teamMemberIds.map (id) ->
    ids.push id

  team.fetchUserRoles ids, (err, roles) ->
    reactor.dispatch actions.FETCH_TEAM_MEMBERS_ROLES_SUCCESS, roles


loadPendingInvites = (invites) ->

  { reactor } = kd.singletons

  options = {}

  new Promise (resolve, reject) ->

    remote.api.JInvitation.some { status: 'pending' }, options, (err, pendings) ->
      if err
        reject err
      invites = invites.map (invite) -> invite.email
      pendingInvitations = pendings.reduce (pendingInvitations, invitation, index) ->
        i = pendingInvitations.size
        return pendingInvitations.set i, toImmutable(invitation)  if invitation.email in invites
        return pendingInvitations
      , immutable.Map()

      resolve { pendingInvitations }


fetchTeamChannels = (channelUrl) ->

  $.ajax
    method : 'GET'
    url : channelUrl
    success : (res) ->
      debugger
      console.log 'res *', res
    error: (err) ->

      console.log 'err* ', err


fetchUsersFromChannel = (usersUrl) ->

  $.ajax
    method : 'GET'
    url : usersUrl
    success : (res) ->
      console.log 'res'
    error: (err) ->
      console.log 'err ', err


sendInvitations = (invites, pendingInvites) ->

  new Promise (resolve, reject) ->
    # return resolve { title: 'There is no body new to send invitation' }  if invites.length is 0
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
    console.log 'pendingInvitations ', pendingInvitations

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
          member = member.set 'role', roles
          reactor.dispatch actions.UPDATE_TEAM_MEMBER, member


module.exports = {
  loadTeam
  updateTeam
  updateInviteInput
  inviteMembers
  fetchMembers
  fetchMembersRole
  loadPendingInvites
  fetchTeamChannels
  fetchUsersFromChannel
  getNewInvitations
  sendInvitations
  resendInvitations
  setSearchInputValue
  handleRoleChange
}
