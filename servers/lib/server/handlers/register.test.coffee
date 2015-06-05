Bongo                                         = require 'bongo'

{ daisy }                                     = Bongo
{ expect }                                    = require "chai"
{ RegisterHandlerHelper : { getPostParams },
  getRandomString }                           = require '../../../testhelper'

hat                                           = require 'hat'
request                                       = require 'request'


###
# Variables
###
postParams = {}


# here we have actual tests
runTests = -> describe 'server.handlers.register', ->

  it 'should send HTTP 400 if username is in use', (done) ->

    randomString = getRandomString()
    postParams   = getPostParams
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

    randomString = getRandomString()
    postParams   = getPostParams
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


  it 'should send HTTP 200 if valid data sent as XHR request', (done) ->

    postParams  = getPostParams()

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 200
      done()


  it 'should send HTTP 301 if request is not XHR',  (done) ->

    postParams = getPostParams
      headers :
        'x-requested-with' : 'this is not an XHR'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      done()


  it 'should pass err if url is not specified', (done) ->

    postParams = getPostParams
      url : ''

    request.post postParams, (err, res, body) ->
      expect(err).to.exist
      done()


runTests()

