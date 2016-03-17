fs      = require 'fs'
tempDir = require 'os-tmpdir'

exports.command = writeCollabLink = (url, callback) ->

  path = "#{tempDir()}/collabLink.txt"

  try
    fs.writeFileSync path, url
    callback? url
  catch
    console.log 'Failed to write collab link file.'

  return this
