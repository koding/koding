koding = require '../bongo'
KONFIG  = require 'koding-config-manager'
async = require 'async'
{ validateEmail } = require './checkers'

fetchGroupMembersAndInvitations = (client, data, callback) ->

  { JGroup, JInvitation } = koding.models
  { group: slug } = client.context
  { connection: { delegate: account } } = client

  queue = [
    (next) ->
      JGroup.one { slug }, (err, group) ->

        return next err  if err
        group.countMembers (err, count) ->
          return next err  if err
          return next 'There are more than 100 members', null  if count > 100

          group.fetchMembersWithEmail client, {}, (err, accounts) ->
            return next err  if err
            next null, accounts.map (account) -> account?.profile?.email

    (next) ->
      account.fetchEmail (err, email) ->

        return next null, null  if err
        next null, email

    (next) ->
      JInvitation.some$ client, { status: 'pending' }, {}, (err, invitations) ->

        return next null, []  if err

        pendingEmails = []
        invitations.map (invitation) ->
          pendingEmails.push invitation.email

        next null, pendingEmails
  ]

  async.series queue, (err, results) ->

    [ userEmails, myEmail, pendingEmails ] = results
    results = { userEmails, myEmail, pendingEmails }

    return callback err, results


analyzedInvitationResults = (params) ->

  myself = no
  adminEmails = 0
  membersEmails = 0
  alreadyMemberEmails = 0
  alreadyInvitedEmails = 0
  notValidInvites = 0

  { data, userEmails, pendingEmails, myEmail } = params

  invitationCount = data.length

  while invitationCount > 0
    invitationCount = invitationCount - 1
    invite = data[invitationCount]
    invite.role = invite.role?.toLowerCase()

    if not validateEmail(invite.email) or not invite.role
      notValidInvites = notValidInvites + 1
      data.splice invitationCount, 1
      continue

    if invite.role
      if invite.role isnt 'admin' and invite.role isnt 'member'
        notValidInvites = notValidInvites + 1
        data.splice invitationCount, 1
        continue

    if invite.email is myEmail
      data.splice invitationCount, 1
      notValidInvites = notValidInvites + 1
      myself = yes
      continue

    if invite.email in pendingEmails
      data.splice invitationCount, 1
      alreadyInvitedEmails = alreadyInvitedEmails + 1
      continue

    if invite.email in userEmails
      data.splice invitationCount, 1
      alreadyMemberEmails = alreadyMemberEmails + 1
      continue

    if invite.role is 'admin'
      adminEmails = adminEmails + 1
      continue

    if invite.role is 'member'
      membersEmails = membersEmails + 1
      continue

  result =
    myself: myself
    admins : adminEmails
    members: membersEmails
    extras :
      alreadyMembers: alreadyMemberEmails
      notValidInvites: notValidInvites
      alreadyInvited: alreadyInvitedEmails

  return { result, data }

module.exports = {
  fetchGroupMembersAndInvitations
  analyzedInvitationResults
}
