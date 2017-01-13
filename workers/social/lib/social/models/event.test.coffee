# Test Model
JEvent = require './event'

# Helpers
{ daisy,
  expect,
  generateRandomString,
  checkBongoConnectivity } = require '../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = ->

  describe 'workers.social.event', ->

    log = generateRandomString()

    it 'should create a counter if not exists', (done) ->

      JEvent.log()


afterTests = ->

  after (done) -> done()


beforeTests()

runTests()

afterTests()
