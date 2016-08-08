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

      { connection: { delegate: account } } = client
      { _id } = account
      myEmail = null
      account.fetchEmail (err, email) ->

        myEmail = email

        { JGroup } = (require './../bongo').models
        { group: slug } = client.context
        JGroup.one { slug }, (err, group) ->
          return callback err, null  if err

          group.fetchMembersWithEmail client, {}, (err, users) ->
            return callback err, null  if err
            return callback null, 'Over 100 Invitation'  if users.length > 100

            userEmails = []
            users.map (user) ->
              { profile: { email } } = user
              userEmails.push email

            { JInvitation } = (require './../bongo').models
            JInvitation.some$ client, { status: 'pending' }, {}, (err, invitations) ->

              pendingEmails = []
              invitations.map (invitation) ->
                pendingEmails.push invitation.email

              params = { data, userEmails, pendingEmails, myEmail }
              { result, data } = helpers.analyzedInvitationResults params

              return callback 'Totally Wrong' unless data.length

              return callback null, result


