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
      processInvitations fileName, client, (err, result) ->
        return respond 500, err if err

        respond 200, result

    return req.pipe busboy

processInvitations = (fileName, client, callback) ->
  fs.readFile fileName, 'utf8', (err, content) ->
    return callback err, null if err

    parser content.toString('utf8'), csvParseOpts, (err, data) ->
      return callback err, null if err

      { JInvitation } = (require './../bongo').models
      JInvitation.create client, { invitations: data }, callback
