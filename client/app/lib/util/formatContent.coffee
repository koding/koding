transformTagTokens = require './transformTagTokens'
transformEmails = require './transformEmails'
transformTags = require './transformTags'
formatQuotes = require './formatQuotes'
formatBlockquotes = require './formatBlockquotes'
applyMarkdown = require './applyMarkdown'
expandUsernames = require './expandUsernames'

validator = require 'validator'

module.exports = (body = '') ->

  fns = [
    transformTagTokens
    transformTags
    transformEmails
    formatQuotes
    formatBlockquotes
    applyMarkdown
  ]

  body = fn body for fn in fns
  body = expandUsernames body, 'code, a'

  return body
