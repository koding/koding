koding      = require './../bongo'
request     = require 'request'
KONFIG      = require 'koding-config-manager'
Tracker     = require '../../../../workers/social/lib/social/models/tracker.coffee'

module.exports = (req, res, next) ->

  { params }          = req
  { token }           = params
  { email }           = params
  { JAccount, JUser } = koding.models

  mailgunUnsubscribeEmail email, (err) ->
    return res.status(500).send 'an error occured'  if err

    if token is '0'
      return res.status(200).send 'unsubscribed'
    else
      JUser.one { email }, (err, user) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(404).send 'no user found'     unless user
        return res.status(404).send 'token not right '  if token isnt String(user._id)

        current = user.getAt('emailFrequency') or {}
        current['global'] = false

        user.update { $set: { emailFrequency: current } }, (err) ->
          return res.status(500).send 'an error occured'  if err

          emailFrequency =
            global    : current.global

          Tracker.identify user.username, { emailFrequency }

        return res.status(200).send 'unsubscribed'


mailgunUnsubscribeEmail = (email, callback) ->
  auth = 'Basic ' + new Buffer('api:' + KONFIG.mailgun.privateKey).toString('base64')
  request.post { url:KONFIG.mailgun.unsubscribeURL, headers: { 'Authorization': auth }, form: { address: email, tag: '*' } }, (err, res, raw) ->
    if err
      console.log "[mailgunUnsubscribeEmail] error: #{err}"
    return callback err
