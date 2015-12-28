{ fetchSession }    = require '../../helpers'

{ sendApiError,
  sendApiResponse } = require './helpers'
errors              = require './errors'

KodingLogger        = require '../../../../models/kodinglogger'

module.exports      = (req, res, next) ->

  fetchSession req, res, (err, session) ->

    if err or not session
      return sendApiError res, errors.unauthorizedRequest

    # safe zone

    { q, limit, from, scope } = req.query

    group = session.groupName ? 'koding'
    query = KodingLogger.generateRestrictedQuery group, q, scope

    KodingLogger.search { query, limit, from }, (err, logs) ->

      if err
      then sendApiError    res, err
      else sendApiResponse res, logs
