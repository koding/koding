Bongo             = require 'bongo'
koding            = require './../bongo'
{ argv }          = require 'optimist'
KONFIG            = require('koding-config-manager').load "main.#{argv.c}"
{ environment }   = KONFIG

teamDomain = switch environment
  when 'production'  then '.koding.com'
  when 'development' then '.dev.koding.com'
  else ".#{environment}.koding.com"

module.exports = (req, res, next) ->
  { code } = req.query
  { JTeamInvitation } = koding.models

  JTeamInvitation.byCode code, (err, invitation) ->
    return res.status(400).send err.message  if err?
    return res.status(400).send()  if not invitation

    return res.status(200).send()
