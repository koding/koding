Encoder = require 'htmlencode'

module.exports = (text = '') ->

  input = Encoder.htmlDecode text

  return text  unless (/^>/gm).test input

  val = ''

  for line in input.split '\n'
    line += '\n'  if line[0] is '>'
    val  += "#{line}\n"

  return val
