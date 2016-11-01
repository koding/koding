JGroupLimit = require './grouplimit'
{ expect } = require '../../../../testhelper'


runTests = -> describe 'workers.social.models.group.grouplimit', ->

  describe 'JGroupLimit', ->

    it 'should exist', ->
      expect(JGroupLimit).to.be.a 'function'
      expect(JGroupLimit.set).to.be.a 'function'


runTests()
