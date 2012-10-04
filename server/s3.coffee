hat = require 'hat'
connectStreamS3 = require "connect-stream-s3"
amazon = require("awssum").load("amazon/amazon")

koding = require './bongo'

mime = require 'mime'
{IncomingForm} = require 'formidable'

# give each uploaded file a unique name (up to you to make sure they are unique, this is an example)
module.exports = (config)-> [
  (req, res, next) ->
    clientId = req.cookies.clientid
    koding.models.JSession.fetchSession clientId, (err, session)->
      if err
        next(err)
      else unless session?
        res.send 403, 'Access denied!'
      else
        console.log 'hello?'
        form = new IncomingForm
        form.parse req, console.log
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