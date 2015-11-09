{ daisy
  expect
  request }                    = require '../../testhelper'
{ testCsrfToken }              = require '../../testhelper/handler'
{ generateOAuthRequestParams } = require '../../testhelper/oauthhelper'


runTests = -> describe 'server.handlers.ouath', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateOAuthRequestParams, 'post', done


  it 'should send HTTP 400 when there is no oauth info in session', (done) ->

    oAuthRequestParams = generateOAuthRequestParams()

    request.post oAuthRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.contain 'No foreignAuth'
      done()



runTests()

