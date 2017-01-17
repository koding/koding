async = require 'async'

{ expect, generateRandomString } = require '../../../../testhelper'
{ generateCreateTeamRequestParams } = require '../../../../../../servers/testhelper/handler/teamhelper'
{ checkBongoConnectivity, request } = require '../../../../../../servers/testhelper'

teamutils = require './teamutils'
teamlimits = require './teamlimits'

JGroup = require '../group'
JGroupLimit = require '../group/grouplimit'

beforeTests = -> before (done) -> checkBongoConnectivity done


runTests = -> describe 'workers.social.models.computeproviders.teamutils', (done) ->

  describe 'teamutils', ->

    describe '#fetchLimitData()', ->

      it 'should return hardcoded team limit if it exists', (done) ->

        trialLimits = teamlimits['trial']

        options = { body: { limit: 'trial', slug: "trial-limit-#{generateRandomString 10}" } }

        queue = [
          (next) ->
            generateCreateTeamRequestParams options, (createTeamRequestParams) ->
              request.post createTeamRequestParams, (err, res) ->
                expect(err).to.not.exist
                expect(res.statusCode).to.be.equal 200
                next()

          (next) ->
            JGroup.one { slug: options.body.slug }, (err, group) ->
              expect(err).to.not.exist
              expect(group).to.exist
              expect(group.config.limit).to.be.equal 'trial'
              next()

          (next) ->
            teamutils.fetchLimitData { limit: 'trial' }, (err, limitData) ->
              expect(err).to.not.exist
              expect(limitData).to.exist
              expect(limitData).to.be.eql trialLimits
              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()


      it 'should return a team limit from db if it exists', (done) ->

        createGroupOptions =
          body:
            limit: "awesome-limit-#{generateRandomString 10}"
            slug: "awesome-team-#{generateRandomString 10}"

        onDemandPlanOptions =
          name               : createGroupOptions.body.limit
          member             : 5000
          validFor           : 0
          instancePerMember  : 90
          allowedInstances   : []
          maxInstance        : 9000
          storagePerInstance : 1000
          restrictions       : {}

        _group = null

        queue = [
          (next) ->
            # we are saving a group limit first
            (new JGroupLimit onDemandPlanOptions).save next

          (next) ->
            generateCreateTeamRequestParams createGroupOptions, (createTeamRequestParams) ->
              request.post createTeamRequestParams, (err, res, body) ->
                expect(err).to.not.exist
                expect(res.statusCode).to.be.equal 200
                next()

          (next) ->
            JGroup.one { slug: createGroupOptions.body.slug }, (err, group) ->
              expect(err).to.not.exist
              expect(group).to.exist
              expect(group.config.limit).to.be.equal createGroupOptions.body.limit
              _group = group
              next()

          (next) ->
            teamutils.fetchLimitData _group.config, (err, limitData) ->
              expect(err).to.not.exist
              expect(limitData).to.exist
              expect(limitData.member).to.be.equal 5000
              expect(limitData.validFor).to.be.equal 0
              expect(limitData.instancePerMember).to.be.equal 90
              expect(limitData.maxInstance).to.be.equal 9000
              expect(limitData.storagePerInstance).to.be.equal 1000
              expect(limitData.allowedInstances.length).to.be.eql 0
              expect(limitData.restrictions).to.be.eql {}
              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()


      it 'should return default value when given limit is not even on the db', (done) ->
        createGroupOptions =
          body:
            limit: "nonexistent-limit-#{generateRandomString 10}"
            slug: "limitless-team-#{generateRandomString 10}"

        _group = null

        queue = [
          (next) ->
            generateCreateTeamRequestParams createGroupOptions, (createTeamRequestParams) ->
              request.post createTeamRequestParams, (err, res, body) ->
                expect(err).to.not.exist
                expect(res.statusCode).to.be.equal 200
                next()

          (next) ->
            JGroup.one { slug: createGroupOptions.body.slug }, (err, group) ->
              expect(err).to.not.exist
              expect(group).to.exist
              expect(group.config.limit).to.be.equal createGroupOptions.body.limit
              _group = group
              next()

          (next) ->
            teamutils.fetchLimitData _group.config, (err, limitData) ->
              expect(err).to.not.exist
              expect(limitData).to.be.eql teamlimits.default
              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()


beforeTests()

runTests()
