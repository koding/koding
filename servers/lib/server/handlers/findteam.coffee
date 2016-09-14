koding  = require './../bongo'
async   = require 'async'
Tracker = require '../../../../workers/social/lib/social/models/tracker.coffee'
{ protocol, hostname } = require 'koding-config-manager'
emailsanitize = require '../../../../workers/social/lib/social/models/user/emailsanitize'

module.exports = (req, res) ->

  UNKNOWN_USER_ERROR = 'User not found'

  { email } = req.body
  { JUser } = koding.models

  return res.status(400).send 'Invalid email!'  unless email

  queue = [
    (next) ->
      sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }
      JUser.one { sanitizedEmail }, (err, user) ->
        return next err  if err
        return next UNKNOWN_USER_ERROR  unless user
        next null, user

    (user, next) ->
      user.fetchOwnAccount (err, account) ->
        return next err  if err
        next null, account

    (account, next) ->
      account.fetchRelativeGroups (err, groups) ->
        next err, account, groups

    (account, groups, next) ->
      groups = groups.filter (group) -> group.slug isnt 'koding'

      { profile : { nickname } } = account

      Tracker.identifyAndTrack nickname, {
        to      : email
        subject : Tracker.types.REQUESTED_TEAM_LIST
      }, {
        teams         : groups.map (group) -> helper.createTeamItem group
        findTeamUrl   : "#{protocol}//#{hostname}/Teams/FindTeam"
        createTeamUrl : "#{protocol}//#{hostname}/Teams/Create"
      }, next
  ]

  async.waterfall queue, (err) ->
    if err and err isnt UNKNOWN_USER_ERROR
      return res.status(403).send err.message ? err
    res.status(200).end()


  helper =

    createTeamItem: (group) ->

      { slug, title, customize, invitationCode } = group

      domain  = "#{slug}.#{hostname}"
      rootUrl = "#{protocol}//#{domain}"
      if invitationCode
        joinUrl = "#{rootUrl}/Invitation/#{encodeURIComponent invitationCode}"

      return {
        title
        domain
        rootUrl
        joinUrl
        avatarUrl : customize?.logo
      }
