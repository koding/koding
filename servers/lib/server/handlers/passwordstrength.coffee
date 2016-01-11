koding = require './../bongo'
zxcvbn = require 'coffeenode-zxcvbn'

module.exports = (req, res, next) ->

  { password } = req.body

  return res.status(400).send 'Bad request!'    unless password

  report = zxcvbn password

  return res.status(400).send 'Invalid password!'    unless report
  return res.status(200).send report
