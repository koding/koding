transformTagTokens = require './transformTagTokens'
transformEmails = require './transformEmails'
transformTags = require './transformTags'
formatQuotes = require './formatQuotes'
formatBlockquotes = require './formatBlockquotes'
applyMarkdown = require './applyMarkdown'
expandUsernames = require './expandUsernames'

module.exports = (body = '', fnOptions = {}) ->

  fns =
    tagTokens   : transformTagTokens
    tags        : transformTags
    emails      : transformEmails
    quotes      : formatQuotes
    blockquotes : formatBlockquotes
    markdown    : applyMarkdown

  for name, fn of fns
    body = fn body, fnOptions[name]

  body = expandUsernames body, 'code, a'

  return body
