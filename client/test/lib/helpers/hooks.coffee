AWS      = require 'aws-sdk'
browser_ = null
_        = require 'lodash'

# worker_test_data_exporter
# s3 put only
# Access Key ID: AKIAIWO4ZPTLQEYSOLGA
# Secret Access Key: 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
AWS.config.update accessKeyId: 'AKIAIWO4ZPTLQEYSOLGA', secretAccessKey: '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'

methods =


  before: (browser) ->

    browser.suite = @suiteName
    browser.testData = {}
    browser_ = browser


  beforeEach: (browser) ->

    {name, module} = browser.currentTest
    {suite}        = browser
    start          = Date.now()

    browser.testData[name] = { module, suite, name, start }


  afterEach: (done) ->

    testData = browser_.testData[browser_.currentTest.name]
    testData.end = Date.now()
    testData.duration = testData.end - testData.start
    done()


  after: (browser) ->

    if process.env.DONT_WRITE_TEST_LOGS_TO_S3
      console.log 'ignoring test logs'
      return no

    keys   = []
    values = []
    string = ''

    for name, data of browser.testData
      values.push arr = []

      for key, value of browser.testData[name]
        keys.push key  if keys.indexOf(key) is -1
        arr.push value

    string += keys.join ','
    string += '\n'

    for value in values
      string += value.join ','
      string += '\n'

    [strDay, month, day, year, time] = new Date(Date.now()).toString().split ' '
    date = month + '-' + day + '-' + year + '-' + time

    revision = process.env['REVISION'] or ''

    filename = "#{revision}-#{browser.suite}-#{date}.csv"

    s3 = new AWS.S3 params:
      Key    : filename
      Bucket : 'koding-test-data'

    browser.pause 10000

    s3.createBucket ->
      s3.upload Body: string, (err, res) ->
        if err
          console.log ' ✖ Unable to write test times to S3.'
        else
          console.log " ✔ Test data saved to S3. #{res.Location}"


module.exports =

  init: (module) ->
    _.extend module, methods
