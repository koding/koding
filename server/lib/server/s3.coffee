hat = require 'hat'
# connectStreamS3 = require "connect-stream-s3"
# amazon = require("awssum").load("amazon/amazon")

koding = require './bongo'
# {dash} = require 'bongo'

mime = require 'mime'
{IncomingForm} = require 'formidable'

{BufferedStream} = require './bufferedstream'


# give each uploaded file a unique name (up to you to make sure they are unique, this is an example)
module.exports = (config)->

  s3CreatePath =(username, filename, extension)->
    hash = require('crypto').createHash('sha1').update(filename).digest('hex')
    "/users/#{username}/#{hash}.#{extension}"

  s3 = require('aws2js').load('s3', config.awsAccessKeyId, config.awsSecretAccessKey)
  s3.setBucket config.bucket
  [
    (req, res, next) ->
      req.files = {}
      req.sizes = {}
      next()

    (req, res, next) ->
      form = new IncomingForm
      form.on 'field', (name, value)->
        if /-size$/.test(name)
          req.sizes[name.split('-').slice(0,-1).join('-')] = value
      form.onPart = (part)->
        unless part.mime?
          return IncomingForm::onPart.call @, part
        parts = []
        file = req.files[part.name] =
          stream    : new BufferedStream
          mime      : part.mime
          filename  : part.filename
          extension : mime.extension part.mime
        part.pipe file.stream
      form.parse req
      next()

    (req, res, next) ->
      clientId = req.cookies.clientid
      koding.models.JSession.fetchSession clientId, (err, session)->
        if err
          next(err)
        else unless session?
          req.files.forEach (file)-> file.destroy
          res.send 403, 'Access denied!'
        else
          for own name, file of req.files
            file.path = s3CreatePath(session.username, file.filename, file.extension)
            s3.put(
              file.path
              {
                'content-length'  : req.sizes[name]
                'content-type'    : file.mime
              }
              file.stream
            )
          next()
  ]

  # connectMiddleware:connectStreamS3(
  #   accessKeyId: config.awsAccessKeyId
  #   secretAccessKey: config.awsSecretAccessKey
  #   awsAccountId: config.awsAccountId
  #   region: amazon.US_EAST_1
  #   bucketName: config.bucket
  #   concurrency: 2 # number of concurrent uploads to S3 (default: 3)
  # )