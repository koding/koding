KodingError = require '../error'

SESSION_DATA_CORRUPTED = new KodingError 'Session data corrupted.'

module.exports =

  parseClient: (client) ->

    if not client or not client.context or not client.connection
      return { err: SESSION_DATA_CORRUPTED }

    group    = client.context.group
    username = client.connection.delegate?.profile?.nickname

    if not group or not username
      return { err: SESSION_DATA_CORRUPTED }

    return { group, username }
