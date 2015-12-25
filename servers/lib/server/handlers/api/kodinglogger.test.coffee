{ expect, generateRandomString } = require '../../../../testhelper'
KodingLogger                     = require './kodinglogger'


runTests = -> describe 'KodingLogger', ->


  describe '# generateRestrictedQuery', ->

    it 'should support group based restriction', (done) ->

      group = 'testgroup'
      query = 'something to search'
      scope = 'log'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      expect restrictedQuery
        .to.exist
        .to.be.equal "[#{scope}:#{group}] AND #{query}"

      done()

    it 'should work without providing a query string', (done) ->

      group = 'testgroup'
      query = ''
      scope = 'log'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      expect restrictedQuery
        .to.exist
        .to.be.equal "[#{scope}:#{group}]"

      done()

    it 'should fallback to default scopes when a scope not provided', (done) ->

      group = 'apple'
      query = 'something to search'

      restrictedQuery = KodingLogger.generateRestrictedQuery group, query

      expect restrictedQuery
        .to.exist
        .to.be.equal "([log:apple] OR [error:apple] OR [warn:apple] OR [info:apple]) AND #{query}"

      done()

    it 'should fallback to default scopes when provided scopes are not supported', (done) ->

      group = 'apple'
      query = 'something to search'
      scope = 'some, other, not supported scope'

      restrictedQuery = KodingLogger.generateRestrictedQuery group, query

      expect restrictedQuery
        .to.exist
        .to.be.equal "([log:apple] OR [error:apple] OR [warn:apple] OR [info:apple]) AND #{query}"

      done()

    it 'should ignore scopes that are not supported', (done) ->

      group = 'apple'
      query = 'something to search'
      scope = 'some, other, scope, log, info'

      restrictedQuery = KodingLogger
        .generateRestrictedQuery group, query, scope

      expect restrictedQuery
        .to.exist
        .to.be.equal "([log:apple] OR [info:apple]) AND #{query}"

      done()


  describe '# send', ->

    it 'should send a log to papertrail', (done) ->

      scope = 'log'
      group = 'testgroup'
      log   = generateRandomString()

      query = KodingLogger.generateRestrictedQuery group, log, scope

      KodingLogger.connect()

      KodingLogger.pt.on 'connect', ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length.above 0
          expect(result.logs[0].message).to.be.equal "[#{scope}:#{group}] #{log}"

          KodingLogger.close()

          done()

      KodingLogger.send scope, group, log, no


  describe '# search', ->

    it 'should search log in papertrail', (done) ->

      scope = 'info'
      group = 'testgroup'
      logs  = [ generateRandomString(), generateRandomString() ]

      query = KodingLogger
        .generateRestrictedQuery group, (logs.join ' OR '), scope

      KodingLogger.connect()

      KodingLogger.pt.on 'connect', ->

        KodingLogger.search { query }, (err, result) ->

          expect(err).to.not.exist
          expect(result).to.exist
          expect(result.logs).to.exist
          expect(result.logs).to.have.length(2)
          expect(result.logs[0].message).to.be.equal "[#{scope}:#{group}] #{logs[0]}"
          expect(result.logs[1].message).to.be.equal "[#{scope}:#{group}] #{logs[1]}"

          KodingLogger.close()

          done()

      for log in logs
        KodingLogger.send scope, group, log, no


runTests()
