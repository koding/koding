getGroup = require './getGroup'
getBlockquoteRanges = require './getBlockquoteRanges'
groupifyLink = require './groupifyLink'

module.exports = (text = '') ->

  {slug} = getGroup()

  skipRanges  = getBlockquoteRanges text
  inSkipRange = (position) ->
    for [start, end] in skipRanges
      return yes  if start <= position <= end
    return no

  return text.replace /#(\w+)/g, (match, tag, offset) ->

    return match  if inSkipRange offset

    pre  = text[offset - 1]
    post = text[offset + match.length]

    switch
      when (pre?.match /\S/) and offset isnt 0
        return match
      when post?.match /[,.;:!?]/
        break
      when (post?.match /\S/) and (offset + match.length) isnt text.length
        return match

    href = groupifyLink "/Activity/Topic/#{tag}", no
    return "[##{tag}](#{href})"
