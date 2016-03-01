fs      = require('fs')
tempDir = require 'os-tmpdir'

exports.command = writeCollabLink = (url, callback) ->

  path = "#{tempDir()}/collabLink.txt"

  try
    fs.writeFileSync path, url
  catch err
    console.log err
    throw "Unable to write file: #{path}"

  callback?.call this, url

  return this
