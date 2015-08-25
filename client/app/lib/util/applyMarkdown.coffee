hljs = require 'highlight.js'
marked = require 'marked'

module.exports = (text, options = {})->

  return null unless text

  text = text.replace '\\', '\\\\'

  options.gfm       ?= true
  options.pedantic  ?= false
  options.sanitize  ?= true
  options.breaks    ?= true
  options.paragraphs?= true
  options.tables    ?= true
  options.highlight ?= (text, lang) ->
    if hljs.getLanguage lang
    then hljs.highlight(lang,text).value
    else text

  marked text, options
