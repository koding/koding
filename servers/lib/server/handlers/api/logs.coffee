{ sendApiError
  sendApiResponse
  verifySessionOrApiToken } = require './helpers'

errors          = require './errors'
KodingLogger    = require '../../../../models/kodinglogger'

# TODO Add request caching here ~ GG

module.exports  = (req, res, next) ->

  verifySessionOrApiToken req, res, (data) ->

    { apiToken, session } = data

    group = apiToken?.group or session.groupName

    # safe zone

    { q, limit, from, scope } = req.query

    query = KodingLogger.generateRestrictedQuery group, q, scope

    KodingLogger.search { query, limit, from }, (err, logs) ->

      if err
      then sendApiError    res, err
      else sendApiResponse res, logs
