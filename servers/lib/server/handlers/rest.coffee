{ getAlias } = require './../helpers'

module.exports = (req, res) ->

  {url}      = req
  queryIndex = url.indexOf '?'

  [ urlOnly, query ] = if ~queryIndex
  then [url.slice(0, queryIndex), url.slice(queryIndex)]
  else [url, '']

  redirectTo = if alias = getAlias urlOnly
  then "#{alias}#{query}"
  else "/#!#{urlOnly}#{query}"

  res.redirect 301, redirectTo