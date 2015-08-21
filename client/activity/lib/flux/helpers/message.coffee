_ = require 'lodash'

###*
 * Sanitizes given payload to meet the request criteria.
 *
 * @param {*} payload
 * @param {object} _payload
###
sanitizePayload = (payload) ->

  unless _.isPlainObject payload
    payload = {}

  return payload


module.exports = {
  sanitizePayload
}
