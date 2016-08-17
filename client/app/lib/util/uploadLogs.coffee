s3upload  = require './s3upload'
parseLogs = require './parseLogs'

module.exports = uploadLogs = (callback, prefix, content) ->

  content ?= parseLogs()

  s3upload {
    name: "logs_#{new Date().toISOString()}.txt"
    content
  }, callback
