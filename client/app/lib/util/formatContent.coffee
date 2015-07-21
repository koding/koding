transformTagTokens = require './transformTagTokens'
transformEmails = require './transformEmails'
transformTags = require './transformTags'
formatQuotes = require './formatQuotes'
formatBlockquotes = require './formatBlockquotes'
applyMarkdown = require './applyMarkdown'
expandUsernames = require './expandUsernames'

module.exports = (body = '', markdownOptions = {}) ->

  fns = [
    transformTagTokens
    transformTags
    transformEmails
    formatQuotes
    formatBlockquotes
  ]

  body = fn body for fn in fns
  body = applyMarkdown body, markdownOptions
  body = expandUsernames body, 'code, a'

  return body
