KONFIG = require 'koding-config-manager'
uuid   = require 'uuid'

module.exports = setCrsfToken = (req, res, next) ->

  unless KONFIG.environment is 'production'
    res.header 'Access-Control-Allow-Origin', 'http://dev.koding.com:4000'

  next()  if req?.cookies?._csrf

  { maxAge, secure } = KONFIG.sessionCookie

  csrfToken = uuid.v4()
  # set cookie as pending cookie
  req.pendingCookies or= {}
  req.pendingCookies._csrf = csrfToken

  expires = new Date Date.now() + 360
  res.cookie '_csrf', csrfToken, { expires, secure }

  res
    .json { token: req.pendingCookies._csrf }
    .end()
