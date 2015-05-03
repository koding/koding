koding  = require './../bongo'

module.exports = (req, res) ->

  { JUser } = koding.models
  { username } = req.body

  return res.status(400).send 'Bad request'  unless username?

  JUser.usernameAvailable username, (err, response) =>

    return res.status(400).send 'Bad request'  if err

    {kodingUser, forbidden} = response

    if not kodingUser and not forbidden
      res.status(200).send response
    else
      res.status(400).send response
