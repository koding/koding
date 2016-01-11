_                   = require 'lodash'
kd                  = require 'kd'
twitter             = require 'twitter-text'
getBlockquoteRanges = require './getBlockquoteRanges'

module.exports = (text = '', callback) ->

  skipRanges = getBlockquoteRanges text

  inSkipRange = (position) ->
    for [start, end] in skipRanges
      return yes  if start <= position <= end
    return no

  hashtagsWithIndices = twitter.extractHashtagsWithIndices(text).filter (h) ->
    [start, end] = h.indices
    not (inSkipRange(start) or inSkipRange(end))

  { socialapi } = kd.singletons

  # return a fetcher promise for every occurence of every hashtag. so that we
  # can be sure that all the hashtags are ready before passing down to
  # callback.
  promises = hashtagsWithIndices.map ({hashtag}) ->
    new Promise (resolve, reject) ->
      socialapi.channel.byName {name: hashtag}, (err, channel) ->
        # resolve null for error cases, so that we can filter them
        # down, when we want to use it.
        if err then resolve null else resolve channel

  # fetch all channels with given hashtags, and then replace the ones that
  # exist with the proper links.
  Promise.all(promises).then (channels) ->
    linkableHashtags = channels
      .filter(Boolean) # remove falsy values
      .map (c) -> c.name # return names from channels

    # lastly replace all linkable tags with markdown.
    for hashtag in linkableHashtags
      url  = "/Channels/#{hashtag}"
      tag  = ///##{hashtag}///g
      text = text.replace tag, -> "[##{hashtag}](#{url})"

    callback text

    # return this here so that other places can hook into this
    # via Promise api as well.
    return text
