fs    = require 'fs'
utils = require '../utils/utils.js'

exports.command = deleteMemberInvitation = (callback) ->

  try
    fs.unlinkSync utils.getMemberInvitationPath()
  catch
    console.log 'There was no member invitation file.'

  callback?()

  return this
