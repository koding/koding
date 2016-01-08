{ daisy
  expect
  request }                           = require '../../../testhelper'
{ testCsrfToken }                     = require '../../../testhelper/handler'
{ generateVideoSessionRequestParams } = require '../../../testhelper/handler/videosessionhelper'


runTests = -> describe 'server.handlers.videosession', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateVideoSessionRequestParams, 'post', done


  it 'should send HTTP 404 if request method is not POST', (done) ->

    queue   = []
    methods = ['put', 'patch', 'delete']

    methods.forEach (method) ->
      videoSessionRequestParams = generateVideoSessionRequestParams { method }

      queue.push ->
        request videoSessionRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 404
          queue.next()

    queue.push -> done()

    daisy queue


  it 'should send HTTP 400 if channel id is not set', (done) ->

    videoSessionRequestParams = generateVideoSessionRequestParams
      body        :
        channelId : ''

    request.post videoSessionRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal '{"err":"Channel ID is required."}'
      done()


  it 'should return a video session id with valid request', (done) ->

    videoSessionRequestParams = generateVideoSessionRequestParams()

    request.post videoSessionRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.contain '"sessionId"'
      done()


runTests()
