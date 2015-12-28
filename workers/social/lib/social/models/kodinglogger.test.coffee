{ expect, generateRandomString } = require '../../../testhelper'
KodingLogger                     = require './kodinglogger'


runTests = -> describe 'KodingLogger', ->


  describe '# generateRestrictedQuery', ->

    it 'should support group based restriction', (done) ->

      group = 'testgroup'
      query = 'something to search'
      scope = 'log'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      identifier = KodingLogger.getIdentifier scope, group

      expect restrictedQuery
        .to.exist
        .to.be.equal "#{identifier} AND #{query}"

      done()

    it 'should work without providing a query string', (done) ->

      group = 'testgroup'
      query = ''
      scope = 'log'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      identifier = KodingLogger.getIdentifier scope, group

      expect restrictedQuery
        .to.exist
        .to.be.equal identifier

      done()

    it 'should fallback to default scopes when a scope not provided', (done) ->

      group = 'apple'
      query = 'something to search'

      restrictedQuery = KodingLogger.generateRestrictedQuery group, query

      identifiers = []
      for _scope in KodingLogger.SCOPES
        identifiers.push KodingLogger.getIdentifier _scope, group

      expect restrictedQuery
        .to.exist
        .to.be.equal "(#{identifiers.join ' OR '}) AND #{query}"

      done()

    it 'should fallback to default scopes when provided scopes are not supported', (done) ->

      group = 'apple'
      query = 'something to search'
      scope = 'some, other, not supported scope'

      restrictedQuery = KodingLogger.generateRestrictedQuery group, query

      identifiers = []
      for _scope in KodingLogger.SCOPES
        identifiers.push KodingLogger.getIdentifier _scope, group

      expect restrictedQuery
        .to.exist
        .to.be.equal "(#{identifiers.join ' OR '}) AND #{query}"

      done()

    it 'should ignore scopes that are not supported', (done) ->

      group = 'apple'
      query = 'something to search'
      scope = 'some, other, scope, log, info'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      identifiers = []
      for _scope in ['log', 'info']
        identifiers.push KodingLogger.getIdentifier _scope, group

      expect restrictedQuery
        .to.exist
        .to.be.equal "(#{identifiers.join ' OR '}) AND #{query}"

      done()


  describe '# send', ->

    it 'should send a log to papertrail', (done) ->

      scope = 'log'
      group = 'testgroup'
      log   = generateRandomString()

      query = KodingLogger.generateRestrictedQuery group, log, scope

      identifier = KodingLogger.getIdentifier scope, group

      KodingLogger.connect()

      KodingLogger.pt.on 'connect', ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length.above 0
          expect(result.logs[0].message).to.be.equal "#{identifier} #{log}"

          KodingLogger.close()

          done()

      KodingLogger[scope] group, log


  describe '# search', ->

    it 'should search log in papertrail', (done) ->

      scope = 'info'
      group = 'testgroup'
      logs  = [ generateRandomString(), generateRandomString() ]

      query = KodingLogger
        .generateRestrictedQuery group, (logs.join ' OR '), scope

      identifier = KodingLogger.getIdentifier scope, group

      KodingLogger.connect()

      KodingLogger.pt.on 'connect', ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length(2)
          expect(result.logs[0].message).to.be.equal "#{identifier} #{logs[0]}"
          expect(result.logs[1].message).to.be.equal "#{identifier} #{logs[1]}"

          KodingLogger.close()

          done()

      for log in logs
        KodingLogger[scope] group, log


runTests()
