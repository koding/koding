bongo = require './../bongo'
{ generateFakeClient } = require './../client'

module.exports = (req, res) ->
  generateFakeClient req, res, (err, client, session) ->
    return res.status(500).send err  if err

    delegate = client?.connection?.delegate
    return res.status(400).send 'delegate is not set'  unless delegate

    delegate.fetchMyPermissionsAndRoles client, (err, permissionsAndRoles) ->
      return res.status(500).send err  if err
      return res.status(200).send permissionsAndRoles
