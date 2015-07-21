fs          = require 'fs'
NW          = require '../../../../node_modules/nightwatch/lib/api/element-commands/_waitForElement.js'
AWS         = require 'aws-sdk'
coffee      = require 'coffee-script/register'
config      = require '../../../../../config/main.dev.coffee'
NW_ORG_FAIL = NW::fail


NW::fail = (result, actual, expected, defaultMsg) ->
  api      = @client.api
  test     = api.currentTest
  filename = "#{test.module}-#{test.name}-#{Date.now()}.png"

  { accessKeyId, secretAccessKey } = config().awsKeys.worker_test_data_exporter

  api.saveScreenshot filename, =>
    AWS.config.update { accessKeyId, secretAccessKey }

    s3 = new AWS.S3
      params   :
        Key    : filename
        Bucket : 'koding-test-data'

    options       =
      Key         : filename
      Body        : fs.createReadStream filename
      ContentType : 'image/png'

    s3.createBucket =>
      s3.putObject options, (err, data) =>
        s3path = "https://koding-test-data.s3.amazonaws.com/#{filename}"
        console.log ' ✔ Test screenshot uploaded to', s3path

        NW_ORG_FAIL.call this, result, actual, expected, defaultMsg
