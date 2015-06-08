koding         = require './../bongo'

module.exports = (req, res, next)->

  { JCampaignData } = koding.models
  { body }          = req

  JCampaignData.add body, (err)->
    return res.status(400).send err.message or 'not ok'  if err
    res.status(200).send 'ok'