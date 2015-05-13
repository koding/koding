request = require 'request'


###*
 * Method returns regexp to find a tag with given name
 *
 * @param  {string} tagName
 * @return {RegExp}
###
getTagRegexp = (tagName) -> new RegExp "(<#{tagName}(\s[^>]*)*>)", 'i'


###*
 * Method inserts child tag into a tag with given name
 *
 * @param  {string} body    - html content where change is needed
 * @param  {string} child   - child tag with its inner content
 * @param  {string} tagName - name of parent tag
 * @return {string}         - html content with performed insertion
###
insertChildIntoTag = (body, child, tagName) ->

  regexp = getTagRegexp tagName
  return body.replace regexp, (str) ->
    if str.indexOf('/>') > -1
      "#{str.replace '/>', '>'}#{child}</#{tagName}>"
    else
      str + child


###*
 * Method adds <base> tag with given url into html content
 *
 * @param  {string} body - html content where change is needed
 * @param  {string} url  - base url
 * @return {string}      - html content with added <base> tag
###
addBaseTag = (body, url) ->

  hasHead = getTagRegexp('head').test body
  body    = insertChildIntoTag body, '<head></head>', 'html'  unless hasHead
  body    = insertChildIntoTag body, "<base href='#{url}'></base>", 'head'


###*
 * Method performs a request for marketing snippet page and snippets config
 * which are located on content-rotator github repo and returns their content
 * in the response.
 * For snippet page it also inserts <base> tag in html content to specify that
 * relative urls of static resources should point to github repo
###
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
