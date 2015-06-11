Bongo                           = require 'bongo'

{ daisy }                       = Bongo
{ expect }                      = require "chai"
{ generateRandomString
  RegisterHandlerHelper }       = require '../../../testhelper'
{ generatePostParams }          = RegisterHandlerHelper


hat                             = require 'hat'
request                         = require 'request'


# here we have actual tests
runTests = -> describe 'server.handlers.register', ->

  it 'should send HTTP 404 if method is not allowed', (done) ->

    queue       = []
    methods     = ['put, patch, del']
    postParams  = generatePostParams()

    addRequestToQueue = (queue, method) ->
      postParams.method = method
      request.del postParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should send HTTP 200 if GET request sent to Register hadler url', (done) ->

    request.get generatePostParams().url, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 200
      done()


  it 'should send HTTP 400 if username is not specified', (done) ->

    postParams = generatePostParams
      body        :
        username  : ''

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if password is not specified', (done) ->

    postParams = generatePostParams
      body        :
        password  : ''

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if passwords do not match ', (done) ->

    postParams = generatePostParams
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if username is in use', (done) ->

    randomString = generateRandomString()
    postParams   = generatePostParams
      body        :
        username  : randomString

    queue = [

      ->
        request.post postParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        request.post postParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if email is in use', (done) ->

    randomString = generateRandomString()
    postParams   = generatePostParams
      body    :
        email : "kodingtestuser+#{randomString}@koding.com"

    queue = [

      ->
        request.post postParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        request.post postParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if agree is set as off', (done) ->

    postParams = generatePostParams
      body        :
        agree     : 'off'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 200 if valid data sent as XHR request', (done) ->

    postParams  = generatePostParams()

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 200
      done()


  it 'should send HTTP 301 if request is not XHR',  (done) ->

    postParams = generatePostParams
      headers :
        'x-requested-with' : 'this is not an XHR'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      done()


  it 'should pass err if url is not specified', (done) ->

    postParams = generatePostParams
      url : ''

    request.post postParams, (err, res, body) ->
      expect(err).to.exist
      done()


runTests()

