Bongo                           = require 'bongo'
koding                          = require './../bongo'
request                         = require 'request'
querystring                     = require 'querystring'

{ daisy }                       = Bongo
{ expect }                      = require 'chai'
{ LogoutHandlerHelper }         = require '../../../testhelper'
{ generateLogoutRequestParams } = LogoutHandlerHelper

# here we have actual tests
runTests = -> describe 'server.handlers.logout', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    logoutRequestParams = generateLogoutRequestParams()

    queue       = []
    methods     = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push ->
      logoutRequestParams.method = method
      request logoutRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should send HTTP 301 and redirect and clear cookies', (done) ->

    cookieJar           = request.jar()

    logoutRequestParams = generateLogoutRequestParams
      jar : cookieJar

    url                 = logoutRequestParams.url

    request.post logoutRequestParams, (err, res, body) ->
      cookieString = cookieJar.getCookieString url
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      expect(cookieString)    .to.not.contain 'clientId'
      expect(cookieString)    .to.not.contain 'useOldKoding'
      expect(cookieString)    .to.not.contain 'koding082014'
      done()


runTests()

