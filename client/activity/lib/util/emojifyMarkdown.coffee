emojify = require 'emojify.js'

module.exports = emojifyMarkdown = (element) ->

  isMarkdown = element.classList.contains 'has-markdown'
  element    = element.querySelector '.has-markdown'  unless isMarkdown

  emojify.run element
