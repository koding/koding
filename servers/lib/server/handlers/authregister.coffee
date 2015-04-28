koding                       = require './../bongo'
{ isLoggedIn, authTemplate } = require './../helpers'

module.exports = (req, res) ->
  {key, hostname} = req.params

  isLoggedIn req, res, (err, loggedIn, account)->
    return res.status(401).send authTemplate "Koding Auth Error - 1" if err

    unless loggedIn
      errMessage = "You are not logged in! Please log in with your Koding username and password"
      res.status(401).send authTemplate errMessage
      return

    unless account and account.profile and account.profile.nickname
      errMessage = "Your account is not found, it may be a system error"
      res.status(401).send authTemplate errMessage
      return

    username = account.profile.nickname

    console.log "CREATING KEY WITH HOSTNAME: #{hostname} and KEY: #{key}"
    {JKodingKey} = koding.models
    JKodingKey.registerHostnameAndKey {username, hostname, key}, (err, data)=>
      if err
        res.status(401).send authTemplate err.message
      else
        res.status(200).send authTemplate data