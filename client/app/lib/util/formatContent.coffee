transformTagTokens = require './transformTagTokens'
transformEmails = require './transformEmails'
transformTags = require './transformTags'
formatQuotes = require './formatQuotes'
formatBlockquotes = require './formatBlockquotes'
applyMarkdown = require './applyMarkdown'
expandUsernames = require './expandUsernames'
markdownUrls = require './markdownUrls'

module.exports = (body = '', markdownOptions = {}) ->

  fns = [
    transformTagTokens
    transformTags
    transformEmails
    formatQuotes
    formatBlockquotes
    markdownUrls
  ]

  body = fn body for fn in fns
  body = applyMarkdown body, markdownOptions
  body = expandUsernames body, 'code, a'

  return body
