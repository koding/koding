urlGrabber = require 'app/util/urlGrabber'

module.exports = (text, replaceAndYieldLinks = no) ->
  return null unless text

  links     = []
  linkCount = 0
  urls      = urlGrabber text
  link      = null
  # This will change the original string to either a fully replaced version
  # or a version with temporary replacement strings that will later be replaced
  # with the expanded html tags
  urls.forEach (url) ->

    url         = url.trim()
    originalUrl = url
    hasProtocol = /\w+\:\/\//

    # remove protocol and trailing path
    visibleUrl        = url.replace(hasProtocol, '').replace(/\/.*/, '')
    checkForPostSlash = /\w*(\/\/)+.*\/.+/.test originalUrl # test for // ... / ...

    # url has no protocol
    url = "//#{url}"  if not hasProtocol.test url

    # Just yield a placeholder string for replacement later on
    # this is needed if the text should get shortened, add expanded
    # string to array at corresponding index
    link = "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"
    if replaceAndYieldLinks
      links.push link
      link = "[tempLink#{linkCount++}]"

  if replaceAndYieldLinks
  then { links, text }
  else link
