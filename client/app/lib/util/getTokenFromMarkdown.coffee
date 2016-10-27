hljs = require 'highlight.js'
marked = require 'marked'

module.exports = (text, tokenTypes, options = {}) ->

  return null unless text

  text = text.replace /\\/g, '\\'

  options.gfm        ?= true
  options.pedantic   ?= false
  options.sanitize   ?= true
  options.breaks     ?= true
  options.paragraphs ?= true
  options.tables     ?= true
  options.highlight  ?= (text, lang) ->
    return hljs.highlightAuto(text).value

  tokens = marked.lexer text, options

  for token in tokens when token.type in tokenTypes
    return token.text