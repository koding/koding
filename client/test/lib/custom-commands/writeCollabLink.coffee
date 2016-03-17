fs    = require 'fs'
utils = require '../utils/utils.js'

exports.command = writeCollabLink = (url, callback) ->

  path = utils.getCollabLinkFilePath()

  try
    fs.writeFileSync path, url
    callback? url
  catch
    console.log 'Failed to write collab link file.'

  return this
