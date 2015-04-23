{ isLoggedIn } = require './../helpers'
koding         = require './../bongo'

module.exports = (req, res, next) ->

  { JGroup } = koding.models

  isLoggedIn req, res, (err, loggedIn, account)->

    return next()  if err

    JGroup.render.loggedOut.kodingHome {
      campaign    : 'hackathon'
      bongoModels : koding.models
      loggedIn
      account
    }, (err, content) ->

      return next()  if err

      return res.status(200).send content