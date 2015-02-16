htmlencode = require 'htmlencode'

module.exports = (text = '') ->

  text = htmlencode.htmlDecode text

  return text  unless (/^>/gm).test text

  val = ''

  for line in text.split '\n'
    line += '\n'  if line[0] is '>'
    val  += "#{line}\n"

  return val
