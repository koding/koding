Bongo                           = require 'bongo'
koding                          = require './../bongo'

{ daisy }                       = Bongo
{ expect }                      = require "chai"
{ generateRandomString
  RegisterHandlerHelper }       = require '../../../testhelper'
{ generateRequestParams }       = RegisterHandlerHelper

hat                             = require 'hat'
request                         = require 'request'
querystring                     = require 'querystring'


# here we have actual tests
runTests = -> describe 'server.handlers.register', ->

  it 'should send HTTP 404 if method is not allowed', (done) ->

    queue       = []
    methods     = ['put, patch, del']
    postParams  = generateRequestParams()

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

    request.get generateRequestParams().url, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 200
      done()


  it 'should send HTTP 400 if username is not specified', (done) ->

    postParams = generateRequestParams
      body        :
        username  : ''

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if password is not specified', (done) ->

    postParams = generateRequestParams
      body        :
        password  : ''

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if passwords do not match ', (done) ->

    postParams = generateRequestParams
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 if username is in use', (done) ->

    randomString = generateRandomString()
    postParams   = generateRequestParams
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
    postParams   = generateRequestParams
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

    postParams = generateRequestParams
      body        :
        agree     : 'off'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 200 and save user if valid data sent as XHR', (done) ->

    postParams          = generateRequestParams()
    { username, email } = querystring.parse postParams.body
    { JUser, JAccount } = koding.models

    queue = [

      ->
        # expecting HTTP 200 response
        request.post postParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting user to be saved on mongodb
        params = { username : username }

        JUser.one params, (err, { data : {email, registeredFrom} }) ->
          expect(err)               .to.not.exist
          expect(email)             .to.be.equal email
          queue.next()

      ->
        #expecting acount to be created
        params = { 'profile.nickname' : username }

        JAccount.one params, (err, { data : {profile} }) ->
          expect(err)               .to.not.exist
          expect(profile.nickname)  .to.be.equal username
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 301 if request is not XHR',  (done) ->

    postParams = generateRequestParams
      headers :
        'x-requested-with' : 'this is not an XHR'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      done()


  it 'should pass err if url is not specified', (done) ->

    postParams = generateRequestParams
      url : ''

    request.post postParams, (err, res, body) ->
      expect(err).to.exist
      done()


runTests()

