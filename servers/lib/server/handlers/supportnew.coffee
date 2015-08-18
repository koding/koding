{ isLoggedIn, authTemplate } = require './../helpers'

module.exports = (req, res) ->

  isLoggedIn req, res, (err, loggedIn, account) ->
    return res.status(401).send authTemplate 'Koding Auth Error - 1'  if err

    unless loggedIn
      errMessage = 'You are not logged in! Please log in with your Koding username and password'
      res.status(401).send authTemplate errMessage
      return

    unless account and account.profile and account.profile.nickname
      errMessage = 'Your account is not found, it may be a system error'
      res.status(401).send authTemplate errMessage
      return


    (require '../helpscout') account, req, res
