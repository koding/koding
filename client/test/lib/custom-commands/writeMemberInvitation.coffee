fs    = require 'fs'
utils = require '../utils/utils.js'

exports.command = writeMemberInvitation = (status, callback) ->

  path = utils.getMemberInvitationPath()

  try
    fs.writeFileSync path, status
    callback? status
  catch
    console.log 'Failed to write member invitation status to file.'

  return this
