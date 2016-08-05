os = require 'os'
fs = require 'fs'
hat = require 'hat'
path = require 'path'
Busboy = require 'busboy'
parser = require 'csv-parse'
{ generateFakeClient } = require './../client'

module.exports.parserOpts = csvParseOpts =
  delimiter: ','
  columns: ['email', 'firstName', 'lastName', 'role']
  relax: no # Preserve quotes inside unquoted field.
  relax_column_count: yes
  skip_empty_lines: true
  trim: true # remove whitespaces
  auto_parse: no # convert integers to numbers etc

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

            adminEmails = []
            alreadyMemberEmails = []
            userEmails = []
            myself = no
            membersEmails = []

            users.map (user) ->
              { profile: { email } } = user
              userEmails.push email

            for key in data

              if myEmail? and key.email is myEmail
                myself = yes
                continue

              if key.email in userEmails
                alreadyMemberEmails.push key.email
                continue

              if key.role? and key.role is 'admin'
                adminEmails.push key.email
                continue

              if key.role is null or key.role is 'member'
                membersEmails.push key.email
                continue

            result =
              myself: myself
              alreadyMembers: alreadyMemberEmails
              admins : adminEmails
              members: membersEmails

            return callback null, result
