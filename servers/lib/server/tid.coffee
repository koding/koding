module.exports = (req, res, next) ->

  { tid } = req.cookies

  return next()  unless tid

  req.body.tid = tid

  return next()
