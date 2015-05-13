request = require 'request'


getTagRegexp = (tagName) -> new RegExp "(<#{tagName}(\s[^>]*)*>)", 'i'


insertChildIntoTag = (body, child, tagName) ->

  regexp = getTagRegexp tagName
  return body.replace regexp, (str) ->
    if str.indexOf('/>') > -1
      "#{str.replace '/>', '>'}#{child}</#{tagName}>"
    else
      str + child


addBaseTag = (body, url) ->

  hasHead = getTagRegexp('head').test body
  body    = insertChildIntoTag body, '<head></head>', 'html'  unless hasHead
  body    = insertChildIntoTag body, "<base href='#{url}'></base>", 'head'


module.exports = (req, res) ->

  { name } = req.params

  url      = "http://alex-ionochkin.github.io/content-rotator/snippets/#{name}"
  isConfig = name is 'config.json'
  options  = { url }

  request options, (err, response, body) ->

    return res.status(400).send err  if response.statusCode >= 400

    unless isConfig
      url += '/'  unless url[url.length - 1] is '/'
      body = addBaseTag body, url

    return res.status(200).send body
