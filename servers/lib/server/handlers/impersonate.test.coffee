{ async
  expect
  request
  generateRandomString }              = require '../../../testhelper'
{ testCsrfToken }                     = require '../../../testhelper/handler'
{ generateImpersonateRequestParams }  = require '../../../testhelper/handler/impersonatehelper'


# here we have actual tests
runTests = -> describe 'server.handlers.impersonate', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateImpersonateRequestParams, 'post', done


  it 'should send HTTP 404 if request method is not POST', (done) ->

    queue   = []
    methods = ['put', 'patch', 'delete']

    methods.forEach (method) ->
      imporsonateRequestParams = generateImpersonateRequestParams
        method : method

      queue.push (next) ->
        request imporsonateRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 404
          next()

    async.series queue, done


  it 'should send HTTP 400 if user is non-existent', (done) ->

    imporsonateRequestParams = generateImpersonateRequestParams
      nickname : generateRandomString()

    request.post imporsonateRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.empty
      done()


runTests()
