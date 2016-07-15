koding  = require './../bongo'
async   = require 'async'
Tracker = require '../../../../workers/social/lib/social/models/tracker.coffee'
{ protocol, hostname } = require 'koding-config-manager'
emailsanitize = require '../../../../workers/social/lib/social/models/user/emailsanitize'

module.exports = (req, res) ->

  { email } = req.body
  { JUser } = koding.models

  return res.status(400).send 'Invalid email!'  unless email

  queue = [
    (next) ->
      sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }
      JUser.one { sanitizedEmail }, (err, user) ->
        return next err  if err
        return next 'User not found'  unless user
        next null, user
    (user, next) ->
      username = user.getAt('username')
      user.fetchOwnAccount (err, account) ->
        return next err  if err
        return next 'Account not found'  unless account
        next null, username, account
    (username, account, next) ->
      account.fetchAllParticipatedGroups {}, (err, groups) ->
        return next err  if err
        next null, username, groups
    (username, groups, next) ->
      items = (
        helper.createGroupItem group for group in groups when group.slug isnt 'koding'
      )

      Tracker.identify username, { email }
      Tracker.track username, {
        to         : email
        subject    : Tracker.types.REQUESTED_TEAM_LIST
      }, { items }, next
  ]

  async.waterfall queue, (err, username, groups) ->
    return res.status(403).send err.message ? err  if err
    res.status(200).end()


  helper =

    createGroupItem: (group) ->

      title : group.title
      link  : "#{protocol}//#{group.slug}.#{hostname}/"
