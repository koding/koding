s3upload  = require './s3upload'
parseLogs = require './parseLogs'

module.exports = uploadLogs = (callback, prefix, content) ->

  content ?= parseLogs()
  prefix = "#{prefix}_"  if prefix

  s3upload {
    name: "logs_#{prefix ? ''}#{new Date().toISOString()}.txt"
    content
  }, callback
