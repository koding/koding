{ get } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  errMsg = (msg)->
    {
      "description" : msg
      "error"       : "bad_request"
    }

  {account_id, kloud_key} = req.query

  unless account_id
    return res.status(400).send errMsg "account_id is required"

  unless kloud_key
    return res.status(401).send errMsg "kloud_key is required"

  # Hardcoding is wrong, however this key won't change
  # depending on environments, so there's point of
  # putting it in config : SA
  unless kloud_key is "R1PVxSPvjvDSWdlPRVqRv8IdwXZB"
    return res.status(401).send errMsg "kloud_key is wrong"

  url  = "/payments/subscriptions/#{account_id}"
  url += "?default=false"

  get url, {}, (err, response)->
    return res.status(400).send err  if err

    res.status(200).send response
