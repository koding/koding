_ = require 'lodash'
os = require 'os'
fs = require 'fs'
hat = require 'hat'
path = require 'path'
Busboy = require 'busboy'
parser = require 'csv-parse'
helpers = require '../helpers'
{ generateFakeClient } = require './../client'
{ parserOpts: csvParseOpts } = require './invitetoteambycsv'


module.exports.handler = (req, rres) ->
  generateFakeClient req, rres, (err, client, session) ->
    return rres.status(500).send err  if err

    fileName = path.join(os.tmpDir(), "team-upload-#{session.groupName}-#{hat(32)}.csv")

    respond = (code, message) ->
      fs.unlink(fileName) # clean up after yourself
      return rres.status(code).send message


    busboy = new Busboy {
      headers: req.headers
      fileSize: 1024 * 1024 # 1 mb
    }

    busboy.on 'file', (fieldname, file, filename, encoding, mimetype) ->
      file.pipe(fs.createWriteStream(fileName))

    busboy.on 'finish', ->
      analyzeInvitations fileName, client, (err, result) ->

        return respond 500, err if err

        respond 200, result

    return req.pipe busboy

analyzeInvitations = (fileName, client, callback) ->
  fs.readFile fileName, 'utf8', (err, content) ->
    return callback err, null if err

    parser content.toString('utf8'), csvParseOpts, (err, data) ->
      return callback err, null if err

      invitationCount = data.length

      return callback null, 'Over 100 Invitation'  if invitationCount > 100

      helpers.fetchGroupMembersAndInvitations client, data, (err, params) ->

        if err
          return callback null, err if err is 'There are more than 100 members'
          return callback err


        params = _.assign {}, params, { data }
        { result, data } = helpers.analyzedInvitationResults params

        return callback 'There is no valid data in your csv file' unless data.length

        return callback null, result
