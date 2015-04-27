validator = require 'validator'

module.exports = (str = '') ->

  output = for word in str.split(' ')
    if validator.isEmail word then "[#{word}](mailto:#{word})" else word

  return output.join(' ')