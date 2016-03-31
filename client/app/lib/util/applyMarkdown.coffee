hljs = require 'highlight.js'
marked = require 'marked'

module.exports = (text, options = {}) ->

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

  marked text, options
