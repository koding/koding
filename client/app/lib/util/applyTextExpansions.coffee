emojify = require 'emojify.js'
expandUrls = require './expandUrls'
putShowMore = require './putShowMore'
expandUsernames = require './expandUsernames'

module.exports = (text, shorten) ->
  return '' unless text

  text = text.replace /&#10;/g, ' '

  # Expand URLs with intention to replace them after putShowMore
  { links, text } = expandUrls text, yes

  text = putShowMore text if shorten

  # Reinsert URLs into text
  if links? then for link, i in links
    text = text.replace "[tempLink#{i}]", link

  text = expandUsernames text
  text = emojify.replace text
  return text
  # @expandWwwDotDomains @expandUrls @expandUsernames text
