koding = require './../bongo'

module.exports = (req, res, next) ->

  { params }          = req
  { email }           = params
  { JAccount, JUser } = koding.models

  JUser.one { email }, (err, user) ->

    return res.status(500).send 'an error occured'  if err
    return res.status(404).send 'no user found'     unless user

    JAccount.one { 'profile.nickname' : user.username }, (err, account) ->

      return res.status(500).send 'an error occured'  if err
      return res.status(404).send 'no account found'  unless account

      { data : { profile } } = account

      return res.status(200).send profile
