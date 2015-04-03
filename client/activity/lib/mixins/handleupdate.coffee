Encoder = require 'htmlencode'

module.exports = (fields) ->

  { createdAt, updatedAt, link, payload } = @getData()

  if updatedAt > createdAt
    @setClass 'edited'
    if link?.link_url isnt payload?.link_url and link and payload?.link_embed
      link.link_embed =
        try JSON.parse Encoder.htmlDecode payload.link_embed
        catch e then null
      link.link_url = payload.link_url
      @updateEmbedBox()
  else @unsetClass 'edited'