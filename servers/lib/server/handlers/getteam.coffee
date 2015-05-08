koding                 = require './../bongo'
{ isLoggedIn }         = require './../helpers'
{ generateFakeClient } = require "./../client"

module.exports = (req, res, next)->

  { params, query } = req
  { name }          = params
  { limit }         = query
  { JGroup }        = koding.models

  JGroup.one slug : name, (err, group) ->

    return res.status(500).send 'an error occured'  if err
    return res.status(404).send 'no group found'    unless group
    return res.status(200).send group



