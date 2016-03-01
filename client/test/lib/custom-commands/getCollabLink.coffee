fs      = require('fs')
tempDir = require 'os-tmpdir'

exports.command = getCollabLink = (callback) ->

  path = "#{tempDir()}/collabLink.txt"

  try
    url = fs.readFileSync path, 'utf8'
  catch err
    console.log err
    throw "Unable to read file: #{path}"

  callback?.call this, url

  return this
