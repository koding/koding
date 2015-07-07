koding = require './../bongo'

module.exports = (req, res) ->

  { JName } = koding.models
  { name }  = req.body

  return res.status(400).send 'No domain param is given!'   unless name

  JName.one { name }, (err, jname) ->

    return res.status(500).send 'Please try again!'  if err
    return res.status(400).send 'Domain is taken!'   if jname

    res.status(200).send 'Domain is available!'
