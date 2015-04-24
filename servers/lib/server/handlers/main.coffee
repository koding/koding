{ error_404, isLoggedIn, isInAppRoute } = require './../helpers'

module.exports = (req, res, next)->

  { params }              = req
  { name, section, slug } = params

  path = name
  path = "#{path}/#{section}"  if section
  path = "#{path}/#{slug}"     if slug

  isLoggedIn req, res, (err, loggedIn, account) ->

    return res.status(404).send error_404()  if err

    handler = if isInAppRoute name
    then require('./app')
    else require('./profile')

    handler req, res, next, {loggedIn, account, path}