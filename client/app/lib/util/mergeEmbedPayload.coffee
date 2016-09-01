_ = require 'lodash'

module.exports = mergeEmbedPayload = (payload, embedPayload) ->

  result = _.assign {}, payload

  # If embedPayload is not empty, we overwrite payload with new embed data.
  # Otherwise, we need to exclude all embed props from result
  if embedPayload and embedPayload.link_embed
    result = _.assign result, embedPayload
  else
    delete result.link_url
    delete result.link_embed

  return result
