transformTagTokens = require './transformTagTokens'
transformTags = require './transformTags'
formatQuotes = require './formatQuotes'
formatBlockquotes = require './formatBlockquotes'
applyMarkdown = require './applyMarkdown'
expandUsernames = require './expandUsernames'

module.exports = (body = '') ->

  fns = [
    transformTagTokens
    transformTags
    formatQuotes
    formatBlockquotes
    applyMarkdown
  ]

  body = fn body for fn in fns
  body = expandUsernames body, 'code, a'

  return body
