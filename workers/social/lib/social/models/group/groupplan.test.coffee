JGroupPlan = require './groupplan'
{ expect } = require '../../../../testhelper'


runTests = -> describe 'workers.social.models.group.groupplan', ->

  describe 'JGroupPlan', ->

    it 'should exist', ->
      expect(JGroupPlan).to.be.a 'function'
      expect(JGroupPlan.set).to.be.a 'function'


runTests()
