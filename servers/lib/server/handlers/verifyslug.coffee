koding    = require './../bongo'
Validator = require '../../../../workers/social/lib/social/models/user/validators'
{ validateTeamDomain } = Validator

module.exports = (req, res) ->

  { JName } = koding.models
  { name }  = req.body

  unless KONFIG.environment is 'production'
    res.header 'Access-Control-Allow-Origin', 'http://dev.koding.com:4000'

  return res.status(400).send 'No domain param is given!'  unless name
  return res.status(400).send 'Invalid domain!'  unless validateTeamDomain name

  JName.one { name }, (err, jname) ->

    return res.status(500).send 'Please try again!'  if err
    return res.status(400).send 'Domain is taken!'   if jname

    res.status(200).send 'Domain is available!'
