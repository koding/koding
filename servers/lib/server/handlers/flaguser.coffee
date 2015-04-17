koding = require './../bongo'

module.exports = (req, res)->

  {username, flag} = req.params
  {JAccount}       = koding.models

  JAccount.one 'profile.nickname' : username, (err, account)->
    if err or not account
      state = false
    else
      state = account.checkFlag('super-admin') or account.checkFlag(flag)
    res.end "#{state}"