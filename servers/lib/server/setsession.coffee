{ addReferralCode } = require './helpers'
{ updateCookie }    = require './client'
koding              = require './bongo'
usertracker         = require './../../../workers/usertracker'

module.exports = (req, res, next) ->

  { JSession } = koding.models
  { clientId } = req.cookies

  # fetchClient will validate the clientId.
  # if it is in our db it will return the session it
  # it it is not in db, creates a new one and returns it
  JSession.fetchSession clientId, (err, result) ->

    return next()  if err
    return next()  unless result?.session

    # add referral code into session if there is one
    addReferralCode req, res

    # update clientId cookie
    updateCookie req, res, result.session

    req.cookies.clientId = result.session.clientId

    remoteIp = req.headers['x-forwarded-for'] or req.connection.remoteAddress
    return next()  unless remoteIp

    res.cookie 'clientIPAddress', remoteIp, { maxAge: 900000, httpOnly: no }

    if result?.session?.username
      usertracker.track result.session.username

    JSession.updateClientIP result.session.clientId, remoteIp, (err) ->
      console.log err  if err?
      next()
