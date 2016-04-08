AWS = require 'aws-sdk'
unless process.env.TEST_AWS_REGION
  console.error 'error: TEST_AWS_REGION is not set'
  process.exit 1

unless process.env.TEST_AWS_ACCESS_KEY
  console.error 'error: TEST_AWS_ACCESS_KEY is not set'
  process.exit 1

unless process.env.TEST_AWS_SECRET_KEY
  console.error 'error: TEST_AWS_SECRET_KEY is not set'
  process.exit 1

AWS.config.region = process.env.TEST_AWS_REGION
AWS.config.update
  accessKeyId     : process.env.TEST_AWS_ACCESS_KEY
  secretAccessKey : process.env.TEST_AWS_SECRET_KEY

module.exports = AWS
