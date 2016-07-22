async = require 'async'

{ expect, generateRandomString } = require '../../../../testhelper'
{ generateCreateTeamRequestParams } = require '../../../../../../servers/testhelper/handler/teamhelper'
{ checkBongoConnectivity, request } = require '../../../../../../servers/testhelper'

teamutils = require './teamutils'
teamplans = require './teamplans'

JGroup = require '../group'
JGroupPlan = require '../group/groupplan'

beforeTests = -> before (done) -> checkBongoConnectivity done


runTests = -> describe 'workers.social.models.computeproviders.teamutils', (done) ->

  describe 'teamutils', ->

    describe '#getPlanData()', ->

      it 'should return hardcoded team plan if it exists', (done) ->

        trialPlan = teamplans['trial']

        options = { body: { plan: 'trial', slug: "trial-plan-#{generateRandomString 10}" } }

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
              expect(group.config.plan).to.be.equal 'trial'
              next()

          (next) ->
            teamutils.getPlanData { plan: 'trial' }, (err, planData) ->
              expect(err).to.not.exist
              expect(planData).to.exist
              expect(planData).to.be.eql trialPlan
              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()


      it 'should return a team plan from db if it exists', (done) ->

        createGroupOptions =
          body:
            plan: "awesome-plan-#{generateRandomString 10}"
            slug: "awesome-team-#{generateRandomString 10}"

        onDemandPlanOptions =
          name               : createGroupOptions.body.plan
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
            # we are saving a group plan first
            (new JGroupPlan onDemandPlanOptions).save next

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
              expect(group.config.plan).to.be.equal createGroupOptions.body.plan
              _group = group
              next()

          (next) ->
            teamutils.getPlanData _group.config, (err, planData) ->
              expect(err).to.not.exist
              expect(planData).to.exist
              expect(planData.member).to.be.equal 5000
              expect(planData.validFor).to.be.equal 0
              expect(planData.instancePerMember).to.be.equal 90
              expect(planData.maxInstance).to.be.equal 9000
              expect(planData.storagePerInstance).to.be.equal 1000
              expect(planData.allowedInstances.length).to.be.eql 0
              expect(planData.restrictions).to.be.eql {}
              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()


      it 'should return default value when given plan is not even on the db', ->
        createGroupOptions =
          body:
            plan: "nonexistent-plan-#{generateRandomString 10}"
            slug: "team-with-nonexistent-plan-config-#{generateRandomString 10}"

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
              expect(group.config.plan).to.be.equal createGroupOptions.body.plan
              _group = group
              next()

          (next) ->
            teamutils.getPlanData _group.config, (err, planData) ->
              expect(err).to.not.exist

              expect(planData).to.be.eql teamplans.default

              next()
        ]

        async.series queue, (err) ->
          expect(err).to.not.exist
          done()



beforeTests()

runTests()

