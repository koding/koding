koding = require './../bongo'
Tracker = require '../../../../workers/social/lib/social/models/tracker.coffee'

module.exports = (req, res, next) ->

  { params }          = req
  { token }           = params
  { email }           = params
  { JAccount, JUser } = koding.models

  JUser.one { email }, (err, user) ->

    return res.status(500).send 'an error occured'  if err
    return res.status(404).send 'no user found'     unless user
    return res.status(404).send 'token not right '  if token != String(user._id)

    current = user.getAt('emailFrequency') or {}
    current["global"] = false

    user.update { $set: { emailFrequency: current } }, (err) ->
      return res.status(500).send 'an error occured'  if err

      emailFrequency =
        global    : current.global

      Tracker.identify user.username, { emailFrequency }

    return res.status(200).send 'unsubscribed'
