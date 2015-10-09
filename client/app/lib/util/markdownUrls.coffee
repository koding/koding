urlGrabber = require 'app/util/urlGrabber'
regexps    = require 'app/util/regexps'


formatUrls = (text) ->

  urls          = urlGrabber text
  processedUrls = {}

  for url in urls
    continue  if processedUrls[url]

    urlWithProtocol = unless regexps.hasProtocol.test url
    then "http://#{url}"
    else url

    urlMarkdown = "[#{url}](#{urlWithProtocol})"

    urlRegExp = new RegExp "(\\s|^)(#{url})(\\s|$)", 'g'
    text      = text.replace urlRegExp, (match, p1, p2, p3) -> p1 + urlMarkdown + p3

    processedUrls[url] = yes

  return text


formatUrlsByPosition = (text, startIndex, endIndex) ->

  text = text.substring startIndex, endIndex
  return formatUrls text


module.exports = markdownUrls = (body) ->

  regExp    = new RegExp '(`|```)([^`]+)\\1', 'g'
  prevIndex = 0
  result    = ''

  while match = regExp.exec body
    formattedText   = formatUrlsByPosition body, prevIndex, match.index
    result         += formattedText
    result         += match[0]
    prevIndex       = regExp.lastIndex

  result += formatUrlsByPosition body, prevIndex

  return result

