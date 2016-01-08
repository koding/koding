koding = require './../bongo'

module.exports = (req, res, next) ->

  { params } = req
  { name }   = params
  { JGroup } = koding.models

  JGroup.one { slug : name }, (err, group) ->

    return res.status(500).send 'an error occured'  if err
    return res.status(404).send 'no group found'    unless group
    return res.status(200).send group
