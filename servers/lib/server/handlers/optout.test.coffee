Bongo                           = require 'bongo'
koding                          = require './../bongo'
request                         = require 'request'
querystring                     = require 'querystring'

{ daisy }                       = Bongo
{ expect }                      = require 'chai'
{ OptoutHandlerHelper }         = require '../../../testhelper'
{ generateOptoutRequestParams } = OptoutHandlerHelper

# here we have actual tests
runTests = -> describe 'server.handlers.optout', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    optoutRequestParams = generateOptoutRequestParams()

    queue       = []
    methods     = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push ->
      optoutRequestParams.method = method
      request optoutRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should send HTTP 301 and redirect and set useOldKoding cookie', (done) ->

    cookieJar           = request.jar()

    optoutRequestParams = generateOptoutRequestParams
      jar : cookieJar

    url                 = optoutRequestParams.url

    request.post optoutRequestParams, (err, res, body) ->
      expect(err)                           .to.not.exist
      expect(res.statusCode)                .to.be.equal 301
      expect(cookieJar.getCookieString url) .to.contain 'useOldKoding=true'
      done()


runTests()

