{ expect } = require 'chai'
{ isSoloAccessible } = require './validators'

runTests = -> describe 'workers.social.user.validators', ->

  describe '#isSoloAccessible()', ->

    today = new Date()

    yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)

    tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)

    cases = [
       { #0 account is not set
          account:{}
          expected: yes
      }
      { #1 group is not koding
          account:{ meta:{ createdAt: today } }
          groupName: 'maui'
          expected: yes
      }
      { #2 cutoffDate is later than register date
          account:{ meta:{ createdAt: today } }
          groupName: 'koding'
          cutoffDate: tomorrow
          expected: yes
      }
      { #3 cutoffDate passed
          account:{ meta:{ createdAt: today } }
          groupName: 'koding'
          cutoffDate: yesterday
          env: 'prod'
          expected: no
      }
      { #4 cutoffDate passed but not koding
          account:{ meta:{ createdAt: today } }
          groupName: 'maui'
          cutoffDate: yesterday
          env: 'prod'
          expected: yes
      }
      { #5 even if createdAt greater than cutoffDate but it is dev, should pass
          account:{ meta:{ createdAt: today } }
          groupName: 'koding'
          cutoffDate: yesterday
          env: 'dev'
          expected: yes
      }
      { #6 cutoffDate passed but not koding
          account:{ meta:{ createdAt: today } }
          groupName: 'maui'
          cutoffDate: yesterday
          expected: yes
      }
    ]

    it 'cases should complete successfully', (done) ->
      for i, c of cases
        expect(isSoloAccessible(c)).to.be.equal c.expected
      done()

runTests()
