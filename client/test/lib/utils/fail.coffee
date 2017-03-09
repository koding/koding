fs  = require 'fs'
NW  = require '../../../../node_modules/nightwatch/lib/api/element-commands/_waitForElement.js'
AWS = require 'aws-sdk'

config      = require 'koding-config-manager'
NW_ORG_FAIL = NW::fail


NW::fail = (result, actual, expected, defaultMsg) ->
  api      = @client.api
  test     = api.currentTest
  filename = "#{test.module}-#{test.name}-#{Date.now()}.png"

  { accessKeyId, secretAccessKey } = config.awsKeys.worker_test_data_exporter

  try

    api.saveScreenshot filename, =>
      AWS.config.update { accessKeyId, secretAccessKey }

      s3 = new AWS.S3
        params   :
          Key    : filename
          Bucket : 'kodingdev-test-data'

      options       =
        Key         : filename
        Body        : fs.createReadStream filename
        ContentType : 'image/png'

      try

        s3.createBucket =>
          s3.putObject options, (err, data) =>
            s3path = "https://kodingdev-test-data.s3.amazonaws.com/#{filename}"
            console.log ' ✔ Test screenshot uploaded to', s3path

            try

              logString = ''

              @client.api.getLog 'browser', (logs) =>

                try

                  logString += "#{log.level} #{log.message}\n"  for log in logs

                  s3 = new AWS.S3 { params:
                    Key    : "console.log-#{test.module}-#{test.name}-#{Date.now()}.log"
                    Bucket : 'kodingdev-test-data'
                  }

                  if logString.length
                    s3.upload { Body: logString }, (err, res) =>
                      NW_ORG_FAIL.call this, result, actual, expected, defaultMsg
                      msg = if err then ' ✖ Unable to write console log to S3.' else " ✔ Console log saved to S3. #{res.Location}"
                      console.log msg
                  else
                    console.log ' ✖ There was no browser log available...'
                    NW_ORG_FAIL.call this, result, actual, expected, defaultMsg

                catch e

                  console.log ' ✖ Failed to upload browser logs to s3.', e
                  NW_ORG_FAIL.call this, result, actual, expected, defaultMsg

            catch e

              console.log ' ✖ Failed to get browser logs.', e
              NW_ORG_FAIL.call this, result, actual, expected, defaultMsg

      catch e

        console.log ' ✖ Failed to upload test screenshot to s3.', e
        NW_ORG_FAIL.call this, result, actual, expected, defaultMsg


  catch e

    console.log ' ✖ Failed to take screenshot from selenium driver.', e
    NW_ORG_FAIL.call this, result, actual, expected, defaultMsg
