Encoder = require 'htmlencode'

module.exports = (text = '') ->

  input = Encoder.htmlDecode text

  return text  unless (/^>/gm).test input

  val = ''

  for line in input.split '\n'
    line = if line[0] is '>'
    then ">#{Encoder.XSSEncode line.substring 1}"
    else Encoder.XSSEncode line

    val  += "#{line}\n"

  return val
