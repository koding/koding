hljs = require 'highlight.js'
Encoder = require 'htmlencode'

module.exports = (text = '') ->

  parts = text.split '```'
  for part, index in parts
    blockquote = index %% 2 is 1

    if blockquote
      if match = part.match /^\w+/
        [lang] = match
        if not hljs.getLanguage(lang) or not part.match /^\w+\s*\n/
          part = "\n#{part}"

      parts[index] = "\n```#{Encoder.htmlDecode part}\n```\n"

  parts.join ''
