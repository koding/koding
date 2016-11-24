{ Base } = require 'bongo'

# this file named as socialaccount while it is under social folder, because i
# dont want it to be listed first item while searching for account.coffe in
# sublime ~ CS

# SocialAccount
module.exports = class SocialAccount extends Base
  JAccount      = require '../account'
  JGroup        = require '../group'
  Validators    = require '../group/validators'

  { bareRequest } = require './helper'

  @update = (args...) -> bareRequest 'updateAccount', args...

  do ->
    JAccount = require '../account'
    JUser    = require '../user'

    updateSocialAccount = (username) ->

      JAccount.one { 'profile.nickname' : username }, (err, account) ->
        return console.error err if err?
        return console.error { message: 'account is not valid' } unless account?

        SocialAccount.update {
          id   : account.socialApiId
          nick : username
        }, (err) ->
          if err?
            console.error 'err while updating account in social api', err


    JAccount.on 'UsernameChanged', (data) ->
      { oldUsername, username, isRegistration } = data

      unless oldUsername and username
        return console.error "username: #{username} or oldUsername is not set: #{oldUsername}"

      updateSocialAccount username  unless isRegistration

    # we are updating account when we update email because we dont store email
    # in postgres and social parts fetch email from mongo, we are just
    # triggering account update on postgres, so other services can get that
    # event and operate accordingly
    JUser.on 'EmailChanged', (data) ->
      { username } = data

      unless username
        return console.error "username: #{username} is not set"

      updateSocialAccount username

    JGroup.on 'MemberRemoved', (data) ->
      participantHandler 'removeParticipants', data

    JGroup.on 'MemberAdded', (data) ->
      participantHandler 'addParticipants', data


participantHandler = (funcName, data) ->

  JSession          = require '../session'
  SocialChannel     = require './channel'
  { group, member } = data

  group.fetchAdmin (err, admin) ->
    return console.error 'err while fetching admin', err  if err
    return console.error 'couldnt find admin'  unless admin

    sessionData = { username: admin.profile.nickname, groupName: group.slug }
    JSession.fetchSessionByData sessionData, (err, session) ->
      return console.error 'err while fetching session', err  if err
      return console.error 'couldnt find a session'  unless session

      client = {}
      client.sessionToken = session.clientId
      client.context or= {}
      client.context.group = group.slug
      client.context.user  = admin.profile.nickname
      client.connection or= {}
      client.connection.delegate  = admin
      client.connection.groupName = group.slug

      group.createSocialApiChannels client, (err, socialApiChannels) ->
        return console.error 'couldnt create socialapi channels', err  if err
        { socialApiChannelId, socialApiAnnouncementChannelId } = socialApiChannels

        # ensure member has socialapi id
        member.createSocialApiId (err, socialApiId) ->
          return console.error 'couldnt create socialapi id', err  if err

          options =
            channelId  : socialApiChannelId
            accountIds : [ socialApiId ]

          SocialChannel[funcName] client, options, (err, participants) ->

            return console.error "couldnt #{funcName} user into group socialapi chan", err, options  if err

            # only add koding's members to announcement channel
            return if group.slug isnt 'koding'

            options =
              channelId  : socialApiAnnouncementChannelId
              accountIds : [ socialApiId ]

            SocialChannel[funcName] client, options, (err) ->
              return console.error "couldnt #{funcName} user into group socialapi chan", err, options  if err
