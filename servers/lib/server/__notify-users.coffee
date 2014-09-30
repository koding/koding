bongo = require './bongo'

module.exports = (req, res) ->
  { JUser, JAccount } = bongo.models
  { i } = req.query

  return res.status(400).send {message:'invalid input'}  unless i?

  ids = i.split ','

  JUser.some {_id:$in:ids}, {limit:100}, (err, users) ->
    return res.status(500).send err  if err

    selector = { 'profile.nickname': $in: users.map (u)-> u.username }

    JAccount.all selector, (err, accounts) ->
      return res.status(500).send err  if err

      accounts.forEach (account) ->
        account.sendNotification 'VMMaintenance', {}

      res.status(200).send ok: 1