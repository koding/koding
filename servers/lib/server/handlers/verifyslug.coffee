koding = require './../bongo'

validateTeamDomain = (name) ->

  teamDomainPattern = ///
    ^                     # beginning of the string
    [a-z0-9]+             # one or more 0-9 and/or a-z
    (
      [-]                 # followed by a single dash
      [a-z0-9]+           # one or more (0-9 and/or a-z)
    )*                    # zero or more of the token in parentheses
    $                     # end of string
  ///

  return teamDomainPattern.test name


module.exports = (req, res) ->

  { JName } = koding.models
  { name }  = req.body

  return res.status(400).send 'No domain param is given!'  unless name
  return res.status(400).send 'Invalid domain!'  unless validateTeamDomain name

  JName.one { name }, (err, jname) ->

    return res.status(500).send 'Please try again!'  if err
    return res.status(400).send 'Domain is taken!'   if jname

    res.status(200).send 'Domain is available!'
