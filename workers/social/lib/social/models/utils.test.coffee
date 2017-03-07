{ async, expect, withConvertedUser, checkBongoConnectivity } = require '../../../testhelper'
{ isAddressValid, checkUserPassword } = require './utils'

# making sure we have db connection before tests
beforeTests = -> before (done) ->

  checkBongoConnectivity done

# here we have actual tests
runTests = -> describe 'utils', ->

  describe 'utils::isAddressValid', ->

    it 'should resolve public hostnames and allow', (done) ->
      isAddressValid 'http://google.com/test', (err) ->
        expect(err).to.not.exist
        done()

    it 'should deny private IPs (10.0.0.1)', (done) ->
      isAddressValid 'http://10.0.0.1', (err) ->
        expect(err).to.exist
        expect(err.type).to.be.equal 'PRIVATE_IP'
        done()

    it 'should deny private IPs (127.0.0.1)', (done) ->
      isAddressValid 'http://127.0.0.1', (err) ->
        expect(err).to.exist
        expect(err.type).to.be.equal 'PRIVATE_IP'
        done()

    it 'should deny private IPs (192.168.1.1)', (done) ->
      isAddressValid 'http://192.168.1.1', (err) ->
        expect(err).to.exist
        expect(err.type).to.be.equal 'PRIVATE_IP'
        done()

    it 'should allow public IPs', (done) ->
      isAddressValid 'http://8.8.8.8:3000', (err) ->
        expect(err).to.not.exist
        done()

    it 'should support query strings on addresses', (done) ->
      isAddressValid 'http://yahoo.com?test=foo&bar', (err) ->
        expect(err).to.not.exist
        done()

  describe 'utils::checkUserPassword', ->

    it 'should account data be provided', (done) ->
      password = 'testpass'
      checkUserPassword null, password, (err) ->
        expect(err).to.be.equal 'Account not found'
        done()

    it 'should password be provided', (done) ->
      account = {}
      checkUserPassword account, null, (err) ->
        expect(err).to.be.equal 'Please provide password'
        done()

    it 'should check the password for given account and password', (done) ->
      account = {}
      withConvertedUser { createGroup: yes }, (data) ->
        { group, client, account, userFormData } = data
        queue = [
          (next) ->
            password = 'wrongpassword'
            checkUserPassword account, password, (err) ->
              expect(err).to.be.equal "Your password didn't match with our records"
              next()

          (next) ->
            checkUserPassword account, userFormData.password, (err) ->
              expect(err).to.not.exist
              next()
        ]

        async.series queue, done


beforeTests()

runTests()
