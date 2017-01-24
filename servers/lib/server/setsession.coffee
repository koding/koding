{ addReferralCode } = require './helpers'
{ updateCookie }    = require './client'
koding              = require './bongo'
KONFIG              = require 'koding-config-manager'

module.exports = (req, res, next) ->

  { JSession } = koding.models
  { clientId } = req.cookies

  # It's not good but for now it works, this needs to be fixed ~ GG
  group = if req.subdomains.length > 3 and /(x|n)ip\.io$/.test req.hostname
  then req.subdomains.reverse()[0]
  else req.subdomains[1] ? req.subdomains[0]

  group = 'koding'  if not group or ///^#{group}\.///.test KONFIG.domains.base

  # fetchClient will validate the clientId.
  # if it is in our db it will return the session it
  # it it is not in db, creates a new one and returns it
  JSession.fetchSession { clientId, group }, (err, result) ->

    return next()  if err
    return next()  unless result?.session

    # add referral code into session if there is one
    addReferralCode req, res

    # update clientId cookie
    updateCookie req, res, result.session

    req.cookies.clientId = result.session.clientId

    remoteIp = req.headers['x-forwarded-for'] or req.connection.remoteAddress
    return next()  unless remoteIp

    JSession.updateClientIP result.session.clientId, remoteIp, (err) ->
      console.log err  if err?
      next()
