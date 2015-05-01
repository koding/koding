{ authTemplate } = require './../helpers'
koding           = require './../bongo'

module.exports = (req, res)->
  { key }        = req.params
  { JKodingKey } = koding.models

  JKodingKey.checkKey { key }, (err, status) ->

    return res.status(401).send authTemplate 'Key doesn\'t exist'  unless status

    res.status(200).send result: 'key is added successfully'