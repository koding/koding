_ = require 'lodash'

module.exports = mergeEmbedPayload = (payload, embedPayload) ->

  result = _.assign {}, payload, embedPayload

  unless embedPayload and embedPayload.link_embed
    delete result.link_url
    delete result.link_embed

  return result