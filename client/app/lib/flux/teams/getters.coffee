toImmutable = require 'app/util/toImmutable'
immutable   = require 'immutable'
isEmailValid = require 'app/util/isEmailValid'


team = ['TeamStore']
TeamMembersIdStore = ['TeamMembersIdStore']
UsersStore = ['UsersStore']
TeamMembersRoleStore = ['TeamMembersRoleStore']
searchInputValue = ['TeamSearchInputValueStore']
invitationInputValues = ['TeamInvitationInputValuesStore']
loggedInUserEmail = ['LoggedInUserEmailStore']
pendingInvitations = ['TeamPendingInvitationStore']


membersWithRole = [
  TeamMembersIdStore
  TeamMembersRoleStore
  UsersStore
  (ids, roles, members) ->
    return ids.map (id) ->
      role = roles.get id
      members.get(id).set('role', role)  if role
]

isValidMemberValue = (member, value) ->
  re = new RegExp(value, 'i')

  re.test(member.get('profile').get('email')) or \
  re.test(member.get('profile').get('firstname')) or \
  re.test(member.get('profile').get('lastname'))


filteredMembersWithRole = [
  membersWithRole
  searchInputValue
  (members, value) ->
    return members  if value is ''
    members.filter (member) -> isValidMemberValue member, value
]


invitations = [
  invitationInputValues
  loggedInUserEmail
  (inputValues, ownEmail) ->
    inputValues.filter (value) ->
      email = value.get('email').trim()
      return (email isnt ownEmail) and isEmailValid(email)
]


adminInvitations = [
  invitations
  (invitations) ->
    invitations.filter (value) -> value.get('role') is 'admin'
]

newInvitations = [
  invitations
  pendingInvitations
  (invitations, pendingInvitations) ->
    pendingEmails = pendingInvitations
      .map (i) -> i.get 'email'
      .toArray()

    invitations = invitations.filter (invitation) ->
      invitation.get('email')  not in pendingEmails
]

resendInvitations = [
  invitations
  pendingInvitations
  (invitations, pendingInvitations) ->

    invitationEmails = invitations
      .map (i) -> i.get 'email'
      .toArray()

    pendingInvitations = pendingInvitations.filter (pendingInvitation) ->
      pendingInvitation.get('email') in invitationEmails
]


module.exports = {
  team
  membersWithRole
  TeamMembersIdStore
  invitationInputValues
  searchInputValue
  filteredMembersWithRole
  adminInvitations
  invitations
  newInvitations
  pendingInvitations
  resendInvitations
}