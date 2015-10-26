{ daisy
  expect
  request
  generateRandomString }            = require '../../../testhelper'
{ generateVerifySlugRequestParams } = require '../../../testhelper/handler/verifyslughelper'
{ generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

reservedTeamDomains = require '../../../../workers/social/lib/social/models/user/reservedteamdomains'


runTests = -> describe 'server.handlers.verifyslug', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    queue       = []
    methods     = ['put', 'patch', 'delete']

    methods.forEach (method) ->
      verifySlugRequestParams = generateVerifySlugRequestParams
        method  : method
        body    :
          name  : 'some-domain'

      queue.push ->
        request verifySlugRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 404
          queue.next()

    queue.push -> done()

    daisy queue


  describe 'when team domain is not set', ->

    it 'should send HTTP 400 if team domain is not set', (done) ->

      verifySlugRequestParams = generateVerifySlugRequestParams
        body   :
          name : ''

      request.post  verifySlugRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'No domain param is given!'
        done()


  describe 'when team name is not valid', ->

    it 'should send HTTP 400 if team domain contains invalid characters', (done) ->

      queue = []
      invalidTeamDomains = [
        '-'
        '-domain'
        'domain-'
        '(domain'
        '!domain'
        '#domain'
        'domain@'
        'domain%'
        'domain?'
        'domain☺'
        'domainCamelCase'
        'domain.with.dots'
        'domain with whitespaces'
      ]

      invalidTeamDomains.forEach (invalidTeamDomain) ->
        verifySlugRequestParams = generateVerifySlugRequestParams
          body   :
            name : invalidTeamDomain

        queue.push ->
          request.post verifySlugRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 400
            expect(body)            .to.be.equal 'Invalid domain!'
            queue.next()

      queue.push -> done()

      daisy queue

  describe 'when domain is available', ->

    it 'should send HTTP 200 if domain is valid', (done) ->

      queue = []
      validTeamDomains = [
        'validdomain'
        'valid-domain'
        'valid-domain2'
        'valid-domain-2'
        '3valid-domain'
        '3-valid-domain'
        'valid4-domain'
        'valid-4-domain'
      ]

      validTeamDomains.forEach (validTeamDomain) ->
        verifySlugRequestParams = generateVerifySlugRequestParams
          body   :
            name : validTeamDomain

        queue.push ->
          request.post verifySlugRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            expect(body)            .to.be.equal 'Domain is available!'
            queue.next()

      queue.push -> done()

      daisy queue


  describe 'when domain is taken', ->

    it 'should send http 400', (done) ->

      slug = generateRandomString()

      verifySlugRequestParams = generateVerifySlugRequestParams
        body   :
          name : slug

      queue = [

        ->
          options = { body : { slug } }
          generateCreateTeamRequestParams options, (createTeamRequestParams) ->

            # expecting team to be created
            request.post createTeamRequestParams, (err, res, body) ->
              expect(err)             .to.not.exist
              expect(res.statusCode)  .to.be.equal 200
              queue.next()

        ->
          # expecting HTTP 400 when domain is taken
          request.post verifySlugRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 400
            expect(body)            .to.be.equal 'Domain is taken!'
            queue.next()

        -> done()

      ]

      daisy queue


  describe 'when domain is a reserved one', ->

    it 'should send http 400', (done) ->

      slug = reservedTeamDomains[0]

      verifySlugRequestParams = generateVerifySlugRequestParams
        body   :
          name : slug

      # expecting HTTP 400 when domain is taken
      request.post verifySlugRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'Invalid domain!'
        done()


runTests()


