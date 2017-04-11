JGroupData       = require './groupdata'
{ expect
  withConvertedUser
  generateRandomString
  checkBongoConnectivity } = require '../../../../testhelper'

beforeTests = -> before (done) -> checkBongoConnectivity done

runTests = -> describe 'workers.social.group.groupdata', ->

  describe 'while testing groupdata', ->

    group        = {}
    groupSlug    = generateRandomString()
    adminClient  = {}
    adminAccount = {}

    # before running test cases creating a group
    before (done) ->

      options = { createGroup : yes, context : { group : groupSlug } }
      withConvertedUser options, (data) ->
        { group, client : adminClient, account : adminAccount } = data
        done()


    it 'should create group data if does not exist.', (done) ->

      JGroupData.create groupSlug, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.exist
        expect(data).to.be.an 'object'
        done()

    it 'should not give error while recreating', (done) ->

      JGroupData.create groupSlug, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.exist
        expect(data).to.be.an 'object'
        done()

    it 'should create record if it does not exist', (done) ->

      fakeGroupSlug = generateRandomString()
      JGroupData.fetchData fakeGroupSlug, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.exist
        expect(data).to.be.an 'object'

        JGroupData.one { slug: fakeGroupSlug }, (err, data) ->
          expect(err).to.not.exist
          expect(data).to.exist
          expect(data).to.be.an 'object'
          done()

    it 'fetchDataAt should not be able to get non existing group', (done) ->

      fakeGroupSlug = generateRandomString()
      JGroupData.fetchDataAt fakeGroupSlug, 'path', (err, data) ->
        expect(err).to.not.exist
        expect(data).to.not.exist
        done()

    it 'fetchDataAt should be able to get existing group', (done) ->

      JGroupData.fetchDataAt groupSlug, 'path', (err, data) ->
        expect(err).to.not.exist
        expect(data).to.not.exist # because we dont have 'path' in data
        done()


    it 'modifyData should be able to update existing group', (done) ->

      JGroupData.modifyData groupSlug, { 'test_key__': 'test_value' }, (err) ->
        expect(err).to.not.exist

        JGroupData.fetchData groupSlug, (err, data) ->
          expect(err).to.not.exist

          expect(data).to.exist
          expect(data).to.be.an 'object'

          expect(data.payload).to.exist
          expect(data.payload).to.be.an 'object'

          expect(data.payload.test_key__).to.exist
          expect(data.payload.test_key__).to.be.an 'string'

          JGroupData.fetchDataAt groupSlug, 'test_key__', (err, data) ->
            expect(err).to.not.exist
            expect(data).to.exist
            done()

beforeTests()

runTests()
