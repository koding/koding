{ Base, secure, signature } = require 'bongo'
crypto = require 'crypto'

KONFIG      = require 'koding-config-manager'
KodingError = require '../error'

module.exports = class S3 extends Base

  # Following aws credentials are belong to koding-client
  # user on aws, and it only has permission for following:
  #
  # putObject : arn:bucket:koding-client
  #
  # Do not change it or do not take it from config ~ GG

  AWS_KEY      = KONFIG.awsKeys.worker_koding_client_s3_put_only.accessKeyId
  AWS_SECRET   = KONFIG.awsKeys.worker_koding_client_s3_put_only.secretAccessKey

  AWS_BUCKET   = KONFIG.clientUploadS3BucketName
  AWS_URL      = "https://#{AWS_BUCKET}.s3.amazonaws.com"

  EXPIREIN     = 100     # in seconds.
  MAX_LENGTH   = 1048576 # 1 MB

  @share()

  @set
    sharedMethods      :
      static           :
        generatePolicy : (signature Function)


  @generatePolicy = secure (client, callback = -> ) ->

    { connection: { delegate } } = client

    return callback new KodingError 'Delegate is not set'  unless delegate

    unless delegate.type is 'registered'
      return callback new KodingError 'Not allowed'

    if not AWS_KEY or not AWS_SECRET
      return callback new KodingError \
        'S3 logs upload disabled because of missing configuration'

    { nickname } = delegate.profile

    expiration = new Date(Date.now() + EXPIREIN * 1000).toISOString()

    policy = {
      expiration,
      conditions : [
        { bucket : AWS_BUCKET }
        { acl    : 'public-read' }
        [ 'starts-with', '$key', "user/#{nickname}" ]
        [ 'starts-with', '$Content-Type', '' ]
        [ 'content-length-range', 0, MAX_LENGTH ]
      ]
    }

    policy = new Buffer(JSON.stringify(policy)).toString 'base64'

    signature = crypto
      .createHmac('sha1', AWS_SECRET)
      .update(policy)
      .digest('base64')

    callback null, {

      req_url    : AWS_URL
      upload_url : "user/#{nickname}"
      accessKey  : AWS_KEY

      policy, signature

    }
