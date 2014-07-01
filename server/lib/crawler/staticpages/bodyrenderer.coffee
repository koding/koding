# This code block is copied from client side (activitylistitem).
# As a future work it could be implemented as a node module.

{argv} = require 'optimist'
{uri}  = require('koding-config-manager').load("main.#{argv.c}")

renderBody = (body) ->
  marked = require 'marked'
  # If href goes to outside of koding, add rel=nofollow.
  # this is necessary to prevent link abusers.
  renderer = new marked.Renderer()
  renderer.link= (href, title, text)->
    linkHTML = "<a href=\"#{href}\""
    if title
      linkHTML += " title=\"#{title}\""

    re = new RegExp("#{uri.address}", "g")
    if re.test href
      linkHTML += ">#{text}</a>"
    else
      linkHTML += " rel=\"nofollow\">#{text}</a>"
    return linkHTML

  body = marked body,
    renderer  : renderer
    gfm       : true
    pedantic  : false
    sanitize  : true

  return body


expandUsernames = (body = '') ->

  # default case for regular text
  body.replace /\B\@([\w\-]+)/gim, (u) ->
    username = u.replace "@", ""
    "<a href='#{uri.address}/#{username}' class='profile-link'>#{u}</a>"

formatBody = (body = '') ->

  fns = [
    transformTags
    formatBlockquotes
    renderBody
  ]

  body = fn body for fn in fns
  body = expandUsernames body

  return body


transformTags = (text = '') ->

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

    href = groupifyLink "Activity/Topic/#{tag}"
    return "[##{tag}](#{href})"


getBlockquoteRanges = (text = '') ->

  ranges = []
  read   = 0

  for part, index in text.split '```'
    blockquote = index %% 2 is 1

    if blockquote
      ranges.push [read, read + part.length - 1]

    read += part.length + 3

  return ranges


formatBlockquotes = (text = '') ->

  parts = text.split '```'
  for part, index in parts
    blockquote = index %% 2 is 1

    if blockquote
      if match = part.match /^\w+/
        [lang] = match
        part = "\n#{part}"  unless hljs.getLanguage lang

      parts[index] = "\n```#{part}\n```\n"

  parts.join ''


groupifyLink = (href, slug) ->
  # TODO use this slug parameter after groups are implemented
  # href     = if slug is 'koding' then href else "#{slug}/#{href}"
  href     = "#{uri.address}/#{href}"

  return href

module.exports = {
  formatBody
}
