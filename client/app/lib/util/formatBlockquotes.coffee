hljs = require 'highlight.js'
Encoder = require 'htmlencode'

module.exports = (text = '') ->

  parts = text.split '```'
  for part, index in parts
    blockquote = index %% 2 is 1

    parts[index] = "\n```#{Encoder.htmlDecode part}\n```\n"  if blockquote

  parts.join ''
