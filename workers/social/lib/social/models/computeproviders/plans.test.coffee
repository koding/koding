plans = require './plans'

{ expect } = require '../../../../testhelper'


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.plans', ->

  describe 'plans', ->

    it 'should return plans object', ->
      expect(plans).to.be.an 'object'


runTests()
