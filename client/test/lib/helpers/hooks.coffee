AWS      = require 'aws-sdk'
browser_ = null
_        = require 'lodash'

methods =


  before: (browser) ->

    browser.suite = @suiteName
    browser.testData = {}
    browser_ = browser


  beforeEach: (browser) ->

    { name, module } = browser.currentTest
    { suite }        = browser
    start            = Date.now()

    browser.testData[name] = { module, suite, name, start }


  afterEach: (done) ->

    testData = browser_.testData[browser_.currentTest.name]
    testData.end = Date.now()
    testData.duration = testData.end - testData.start
    done()


  after: (browser) ->

module.exports =

  init: (module) ->
    _.extend module, methods
