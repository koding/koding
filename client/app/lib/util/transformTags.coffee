_                     = require 'lodash'
getGroup              = require './getGroup'
getBlockquoteRanges   = require './getBlockquoteRanges'
groupifyLink          = require './groupifyLink'
twitter               = require 'twitter-text'

module.exports = (text = '', options = {}) ->

  {slug} = getGroup()

  skipRanges  = getBlockquoteRanges text
  inSkipRange = (position) ->
    for [start, end] in skipRanges
      return yes  if start <= position <= end
    return no

  { useReactivityUrl } = options
  hashtags = _.uniq twitter.extractHashtags text
  for hashtag in hashtags
    url  = if useReactivityUrl
    then "/Channels/#{hashtag}"
    else "/Activity/Topic/#{hashtag}"
    url  = groupifyLink url, no
    tag  = "##{hashtag}"
    text = text.replace "#{tag}", (match, offset) ->
      if inSkipRange offset
      then match
      else "[#{tag}](#{url})"

  return text
