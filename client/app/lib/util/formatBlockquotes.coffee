hljs = require 'highlight.js'

module.exports = (text = '') ->

  parts = text.split '```'
  for part, index in parts
    blockquote = index %% 2 is 1

    if blockquote
      if match = part.match /^\w+/
        [lang] = match
        part = "\n#{part}"  unless hljs.getLanguage lang

      parts[index] = "\n```#{part}\n```\n"

  parts.join ''
