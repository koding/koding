Bongo                                     = require 'bongo'
koding                                    = require './../bongo'
request                                   = require 'request'

{ daisy }                                 = Bongo
{ expect }                                = require 'chai'
{ generateUrl
  generateRandomEmail
  generateRandomString
  generateRandomUsername }                = require '../../../testhelper'
{ generateRegisterRequestParams }         = require '../../../testhelper/handler/registerhelper'
{ generateVerifyTokenRequestParams }      = require '../../../testhelper/handler/verifytokenhelper'

JUser                                     = null
JPasswordRecovery                         = null


# here we have actual tests
runTests = -> describe 'server.handlers.verifytoken', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JUser
      JPasswordRecovery } = koding.models

    done()


  it 'should send HTTP 404 if request method is not GET', (done) ->

    verifyTokenRequestParams = generateVerifyTokenRequestParams
      body    :
        email : generateRandomEmail()

    queue       = []
    methods     = ['post', 'put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push ->
      verifyTokenRequestParams.method = method
      request verifyTokenRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should redirect to VerificationFailed page if token is invalid', (done) ->

    token                     = 'invalidToken'
    url                       = generateUrl
      route : "Verify/#{token}"

    verifyTokenRequestParams = generateVerifyTokenRequestParams
      url   : url
      token : token

    request.get verifyTokenRequestParams, (err, res, body) ->
      expect(err)               .to.not.exist
      expect(res.statusCode)    .to.be.equal 200
      expect(res.request.href)  .to.contain 'VerificationFailed'
      done()


  it 'should redirect to Verified page if token is valid', (done) ->

    email       = generateRandomEmail()
    token       = generateRandomString()
    username    = generateRandomUsername()
    certificate = null

    queue = [

      ->
        # generationg a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            email    : email
            username : username

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # generating a new token
        certificate = new JPasswordRecovery {
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : 1000 * 60 * 5 # 5 minutes
        }

        certificate.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting newly created token to be verified
        url                       = generateUrl
          route : "Verify/#{token}"

        verifyTokenRequestParams  = generateVerifyTokenRequestParams
          url   : url
          token : token

        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'Verified'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should redirect to VerificationFailed page if token is expired, redeemed or invalidated', (done) ->

    email       = generateRandomEmail()
    token       = generateRandomString()
    username    = generateRandomUsername()
    certificate = null

    url         = generateUrl
      route : "Verify/#{token}"

    verifyTokenRequestParams  = generateVerifyTokenRequestParams
      url   : url
      token : token

    queue = [

      ->
        # generationg a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            email    : email
            username : username

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # generating a new token
        certificate = new JPasswordRecovery {
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : 1000 * 60 * 5 # 5 minutes
        }

        certificate.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expiring token
        certificate.expire (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting expired token not to pass verification
        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'VerificationFailed'
          queue.next()

      ->
        # activating token again
        certificate.update { $set: { status: 'active' } }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting activated token to pass verification
        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'Verified'
          queue.next()

      ->
        # redeeming token
        certificate.redeem (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting redeemed token not to pass verification
        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'VerificationFailed'
          queue.next()

      ->
        # activating token again
        certificate.update { $set: { status: 'active' } }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting activated token to pass verification
        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'Verified'
          queue.next()

      ->
        # invalidating token
        certificate.update { $set: { status: 'invalidated' } }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting invalidated token not to pass verification
        request.get verifyTokenRequestParams, (err, res, body) ->
          expect(err)               .to.not.exist
          expect(res.statusCode)    .to.be.equal 200
          expect(res.request.href)  .to.contain 'VerificationFailed'
          queue.next()

      -> done()

    ]

    daisy queue


runTests()
