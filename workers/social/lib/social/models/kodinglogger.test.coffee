{ expect, generateRandomString } = require '../../../testhelper'
KodingLogger                     = require './kodinglogger'


runTests = -> describe 'KodingLogger', ->

  it 'should provide helper method for each scope', (done) ->

    for scope in KodingLogger.SCOPES
      expect(KodingLogger[scope]).to.exist

    done()


  describe '# getIdentifier', ->

    it 'should generate an identifier for provided group and scope', (done) ->

      group = 'testgroup'
      scope = 'warn'

      identifier = KodingLogger.getIdentifier scope, group
      expect(identifier).to.be.equal "[#{scope}:#{group}]"

      done()


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


  describe '# connect', ->

    it 'should be able to connect to papertrail', (done) ->

      KodingLogger.close()
      KodingLogger.connect()

      expect(KodingLogger.logger).to.exist
      expect(KodingLogger.pt).to.exist

      KodingLogger.pt.on 'connect', -> done()


  describe '# send', ->

    it.skip 'should send a log to papertrail', (done) ->

      scope = 'log'
      group = 'testgroup'
      log   = generateRandomString()

      query = KodingLogger.generateRestrictedQuery group, log, scope

      identifier = KodingLogger.getIdentifier scope, group

      KodingLogger[scope] group, log

      setTimeout ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length.above 0
          expect(result.logs[0].message).to.be.equal "#{identifier} #{log}"

          done()

      , 4000


  describe '# search', ->

    it.skip 'should search log in papertrail', (done) ->

      scope = 'info'
      group = 'testgroup'
      logs  = [ generateRandomString(), generateRandomString() ]

      query = KodingLogger
        .generateRestrictedQuery group, (logs.join ' OR '), scope

      identifier = KodingLogger.getIdentifier scope, group

      for log in logs
        KodingLogger[scope] group, log

      setTimeout ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length(2)
          expect(result.logs[0].message).to.be.equal "#{identifier} #{logs[0]}"
          expect(result.logs[1].message).to.be.equal "#{identifier} #{logs[1]}"

          done()

      , 9000


  describe '# close', ->

    it 'should close existing connection from papertrail', (done) ->

      expect(KodingLogger.logger).to.exist
      expect(KodingLogger.pt).to.exist

      KodingLogger.close()

      expect(KodingLogger.logger).to.not.exist
      expect(KodingLogger.pt).to.not.exist

      done()


runTests()
