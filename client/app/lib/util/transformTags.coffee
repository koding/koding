getGroup              = require './getGroup'
getBlockquoteRanges   = require './getBlockquoteRanges'
groupifyLink          = require './groupifyLink'
twitter               = require 'twitter-text'

module.exports = (text = '') ->

  {slug} = getGroup()

  skipRanges  = getBlockquoteRanges text
  inSkipRange = (position) ->
    for [start, end] in skipRanges
      return yes  if start <= position <= end
    return no

  hashtags = twitter.extractHashtags text
  for hashtag in hashtags
    href = groupifyLink "/Activity/Topic/#{hashtag}", no
    tag = "##{hashtag}"
    url =  "[#{tag}](#{href})"

    text = text.replace "#{tag}", url
  
  return text
