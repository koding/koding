fs    = require 'fs'
utils = require '../utils/utils.js'

exports.command = deleteCollabLink = (callback) ->

  try
    fs.unlinkSync utils.getCollabLinkFilePath()
  catch
    console.log 'There was no collab link file.'

  callback?()

  return this
