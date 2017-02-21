AWS = require 'aws-sdk'

KONFIG = require 'koding-config-manager'

unless KONFIG.test?.credentials?.AWS
  console.error 'error: test aws credentials are not set'
  process.exit 1

{
  region
  accessKeyId
  secretAccessKey
} = KONFIG.test.credentials.AWS

unless region
  console.error 'error: region is not set'
  process.exit 1

unless accessKeyId
  console.error 'error: access key id is not set'
  process.exit 1

unless secretAccessKey
  console.error 'error: secret access key is not set'
  process.exit 1

AWS.config.region = region
AWS.config.update { accessKeyId, secretAccessKey }

module.exports = AWS
