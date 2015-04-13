_         = require 'lodash'
validator = require 'validator'

module.exports = (str) ->

  words = str.split(' ')
  urls  = _.uniq (word for word in words when validator.isURL(word) and not validator.isEmail(word) ) or []

  return urls
