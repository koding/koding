JSnapshot = require './snapshot'

{ daisy
  expect
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity }    = require '../../../../testhelper'
{ withConvertedUserAndSnapshot } = require '../../../../testhelper/models/computeproviders/snapshothelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.snapshot', ->

  describe '#verifySnapshot()', ->

    it 'should fail to verify if snapshotId is not specified', (done) ->

      withConvertedUser ({ client }) ->
        JSnapshot.verifySnapshot client, { snapshotId : null }, (err) ->
          expect(err?.message).to.be.equal 'snapshotId is not provided'
          done()


    it 'should fail to verify if storage is no sufficient', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        options = { storage : 0, snapshotId : snapshot.snapshotId }
        JSnapshot.verifySnapshot client, options, (err) ->
          expect(err?.message).to.be.equal 'Storage size is not enough for this snapshot'
          done()


    it 'should be able to verify snapshot when correct data provided', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        options = { snapshotId : snapshot.snapshotId }
        JSnapshot.verifySnapshot client, options, (err, snapshot_) ->
          expect(err).to.not.exist
          expect(snapshot_).to.exist
          expect(snapshot.label).to.be.equal snapshot_.label
          done()


  describe '#one$()', ->

    it 'should fail to fetch snapshot data if user doesnt have permission', (done) ->

      expectAccessDenied JSnapshot, 'one$', snapshotId = null, done


    it 'should be able to fetch the snapshot data', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        JSnapshot.one$ client, snapshot.snapshotId, (err, snapshot_) ->
          expect(err).to.not.exist
          expect(snapshot).exist
          expect(snapshot.label).to.be.equal snapshot_.label
          expect(snapshot.originId).to.be.deep.equal snapshot_.originId
          expect(snapshot.machineId).to.be.deep.equal snapshot_.machineId
          done()


  describe '#some$()', ->

    it 'should fail to fetch snapshot data if user doesnt have permission', (done) ->

      expectAccessDenied JSnapshot, 'some$', selector = {}, options = {}, done


    it 'should be able to fetch snapshot data', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        selector = { snapshotId : snapshot.snapshotId }
        JSnapshot.some$ client, selector, {}, (err, snapshots) ->
          expect(err).to.not.exist
          expect(snapshots).to.be.an 'array'
          expect(snapshots[0].label).to.be.equal snapshot.label
          expect(snapshots[0].originId).to.be.deep.equal snapshot.originId
          expect(snapshots[0].machineId).to.be.deep.equal snapshot.machineId
          done()


  describe 'rename()', ->

    it 'should fail to rename snapshot if user doesnt have permission', (done) ->

      withConvertedUserAndSnapshot ({ snapshot }) ->
        expectAccessDenied snapshot, 'rename', label = 'someLabel', done


    it 'should fail to rename snapshot if label is empty', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        label    = snapshot.label
        selector = { snapshotId : snapshot.snapshotId }
        snapshot.rename client, '', (err) ->
          expect(err?.message).to.be.equal 'JSnapshot.rename: label is empty'
          done()

    it 'should fetch the snapshot data', (done) ->

      withConvertedUserAndSnapshot ({ client, snapshot }) ->
        label    = snapshot.label
        selector = { snapshotId : snapshot.snapshotId }
        snapshot.rename client, 'newLabel', (err) ->
          expect(err).to.not.exist
          expect(snapshot.label).not.to.be.equal label
          expect(snapshot.label).to.be.equal 'newLabel'
          done()



beforeTests()

runTests()

