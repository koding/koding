bongo = require './bongo'

module.exports = (req, res) ->
  { JUser, JAccount } = bongo.models
  { i } = req.query

  return res.send 400, {message:'invalid input'}  unless i?

  ids = i.split ','

  JUser.some {_id:$in:ids}, {limit:100}, (err, users) ->
    return res.send 500, err  if err

    selector = { 'profile.nickname': $in: users.map (u)-> u.username }

    JAccount.all selector, (err, accounts) ->
      return res.send 500, err  if err

      accounts.forEach (account) ->
        account.sendNotification 'VMMaintenance', {}

      res.send 200, ok: 1