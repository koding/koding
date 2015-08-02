###*
 * Sanitizes given payload to meet the request criteria.
 *
 * @param {*} payload
 * @param {object} _payload
###
sanitizePayload = (payload) ->

  unless typeof payload is 'object'
    payload = {}

  return payload


module.exports = {
  sanitizePayload
}
