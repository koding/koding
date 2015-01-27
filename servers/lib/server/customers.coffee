{ get } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  errMsg = (msg)->
    {
      "description" : msg
      "error"       : "bad_request"
    }

  {key} = req.query

  unless key
    return res.status(401).send errMsg "key is required"

  # Hardcoding is wrong, however this key won't change
  # depending on environments, so there's point of
  # putting it in config : SA
  unless key is "R1PVxSPvjvDSWdlPRVqRv8IdwXZB"
    return res.status(401).send errMsg "key is wrong"

  url  = "/payments/customers"

  get url, {}, (err, response)->
    return res.status(400).send err  if err

    res.status(200).send response
