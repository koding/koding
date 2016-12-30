{ error_404, isLoggedIn, isInAppRoute } = require './../helpers'

module.exports = (req, res, next) ->

  { params }              = req
  { name, section, slug } = params

  path = name
  path = "#{path}/#{section}"  if section
  path = "#{path}/#{slug}"     if slug

  isLoggedIn req, res, (err, loggedIn, account) ->

    return res.status(404).send error_404()  if err
    return res.status(404).send error_404()  unless isInAppRoute name
    return res.status(404).send error_404()  if name is 'Activity'
    return next()
