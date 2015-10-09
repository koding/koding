module.exports = (req, res, next) ->

  { _csrf } = req.cookies

  if _csrf isnt getToken req
    return res.status(403).send '_csrf token is not valid'

  return next()

getToken = (req) ->
  req.body?._csrf or
  req.query?._csrf or
  req.headers['csrf-token'] or
  req.headers['xsrf-token'] or
  req.headers['x-csrf-token'] or
  req.headers['x-xsrf-token']
