module.exports = (text, replaceAndYieldLinks=no) ->
  return null unless text

  links = []
  linkCount = 0

  urlGrabber = ///
  (?!\s)                                                      # leading spaces
  ([a-zA-Z]+://)                                              # protocol
  (\w+:\w+@|[\w|\d]+@|)                                       # username:password@
  ((?:[a-zA-Z\d]+(?:-[a-zA-Z\d]+)*\.)*)                       # subdomains
  ([a-zA-Z\d]+(?:[a-zA-Z\d]|-(?=[a-zA-Z\d]))*[a-zA-Z\d]?)     # domain
  \.                                                          # dot
  ([a-zA-Z]{2,4})                                             # top-level-domain
  (:\d+|)                                                     # :port
  (/\S*|)                                                     # rest of url
  (?!\S)
  ///g


  # This will change the original string to either a fully replaced version
  # or a version with temporary replacement strings that will later be replaced
  # with the expanded html tags
  text = text.replace urlGrabber, (url) ->

    url = url.trim()
    originalUrl = url

    # remove protocol and trailing path
    visibleUrl = url.replace(/(ht|f)tp(s)?\:\/\//,"").replace(/\/.*/,"")
    checkForPostSlash = /.*(\/\/)+.*\/.+/.test originalUrl # test for // ... / ...

    if not /[A-Za-z]+:\/\//.test url

      # url has no protocol
      url = '//'+url

    # Just yield a placeholder string for replacement later on
    # this is needed if the text should get shortened, add expanded
    # string to array at corresponding index
    if replaceAndYieldLinks
      links.push "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"
      "[tempLink#{linkCount++}]"
    else
      # yield the replacement inline (good for non-shortened text)
      "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"

  if replaceAndYieldLinks
    {
      links
      text
    }
  else
    text
