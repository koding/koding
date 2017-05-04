{
  expect
  withDummyClient
  withConvertedUser
  checkBongoConnectivity
} = require '../../../../testhelper'
JPermissionSet = require './permissionset'

beforeTests = -> before (done) ->

  checkBongoConnectivity done

runTests = -> describe 'workers.social.models.group.permissionset', ->

  describe 'JPermissionSet', ->

    it 'should exist', ->
      expect(JPermissionSet).to.be.a 'function'
      expect(JPermissionSet.set).to.be.a 'function'
      expect(JPermissionSet.permit).to.be.a 'function'
      expect(JPermissionSet.checkPermission).to.be.a 'function'

    describe 'permit()', ->

      describe 'should support simple permissions', ->

        it 'should deny for guests', (done) ->
          withDummyClient ({ client }) ->
            (JPermissionSet.permit \
              'open group', { failure: -> done() }) client

        it 'should allow for members', (done) ->
          withConvertedUser ({ client }) ->
            (JPermissionSet.permit \
              'open group', { success: -> done() }) client


      describe 'should support advanced permissions', ->

        it 'should deny for guests', (done) ->
          withDummyClient ({ client }) ->
            (JPermissionSet.permit {
              advanced : [ { permission: 'open group' } ]
              failure  : -> done()
            }) client

        it 'should allow for members', (done) ->
          withConvertedUser ({ client }) ->
            (JPermissionSet.permit {
              advanced : [ { permission: 'open group' } ]
              success  : -> done()
            }) client


      describe 'should support multiple permissions', ->

        it 'should deny for guests', (done) ->
          withDummyClient ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'grant access' }
                { permission: 'open group' }
              ]
              failure  : -> done()
            }) client

        it 'should allow for members', (done) ->
          withConvertedUser ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'grant access' }
                { permission: 'open group' }
              ]
              success  : -> done()
            }) client


      describe 'should support validators', ->

        it 'should deny for guests when validator returned no', (done) ->
          withDummyClient ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'open group', validateWith: (..., cb) -> cb null, no }
              ]
              failure  : -> done()
            }) client

        it 'should allow for guests when validator returned yes', (done) ->
          withDummyClient ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'open group', validateWith: (..., cb) -> cb null, yes }
              ]
              success  : -> done()
            }) client

        it 'should deny for members when validator returned no', (done) ->
          withConvertedUser ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'open group', validateWith: (..., cb) -> cb null, no }
              ]
              failure  : -> done()
            }) client

        it 'should allow for guests when validator returned yes', (done) ->
          withConvertedUser ({ client }) ->
            (JPermissionSet.permit {
              advanced : [
                { permission: 'open group', validateWith: (..., cb) -> cb null, yes }
              ]
              success  : -> done()
            }) client


beforeTests()

runTests()
