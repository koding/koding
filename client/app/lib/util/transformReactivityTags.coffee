_                   = require 'lodash'
getGroup            = require './getGroup'
getBlockquoteRanges = require './getBlockquoteRanges'
twitter             = require 'twitter-text'

module.exports = (text = '') ->

  {slug} = getGroup()

  skipRanges  = getBlockquoteRanges text
  inSkipRange = (position) ->
    for [start, end] in skipRanges
      return yes  if start <= position <= end
    return no

  hashtags = _.uniq twitter.extractHashtags text
  for hashtag in hashtags
    url  = "/Channels/#{hashtag}"
    tag  = "##{hashtag}"
    text = text.replace "#{tag}", (match, offset) ->
      if inSkipRange offset
      then match
      else "[#{tag}](#{url})"

  return text

