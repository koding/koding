{ isLoggedIn } = require './../helpers'
koding         = require './../bongo'

module.exports = (req, res, next)->

  {JWFGH} = koding.models

  isLoggedIn req, res, (err, loggedIn, account)->

    return res.status(400).send 'not ok' unless loggedIn

    JWFGH.apply account, (err, stats)->
      return res.status(400).send err.message or 'not ok'  if err
      res.status(200).send stats