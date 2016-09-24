{ expect } = require '../../testhelper'
{ isTeamPage, isAddressValid } = require './helpers'


describe 'helpers::isTeamPage', ->

  generateReq = (name) ->
    req = {}
    req.headers = {}
    req.headers['x-host'] = name
    return req

  cases = [
      { host: undefined,                          expected: no }
      { host: '',                                 expected: no }
      { host: 'koding.com',                       expected: no }
      { host: 'latest.koding.com',                expected: no }
      { host: 'sandbox.koding.com',               expected: no }
      { host: 'dev.koding.com:8090',              expected: no }
      { host: 'dev.koding.com',                   expected: no }
      { host: 'https://dev.koding.com',           expected: no }
      { host: 'https://dev.koding.com:8090',      expected: no }
      { host: 'hawaii.dev.koding.com',            expected: yes }
      { host: 'hawaii.koding.com',                expected: yes }
      { host: 'hawaii.latest.koding.com',         expected: yes }
      { host: 'hawaii.sandbox.koding.com',        expected: yes }
      { host: 'hawaii.sandbox.koding.com:8090',   expected: yes }
      { host: '192.168.24.1',                     expected: no }
      { host: 'http://192.168.24.1',              expected: no }
      { host: 'http://192.168.24.1:8090',         expected: no }
  ]

  it 'cases should complete successfully', (done) ->
    for i, req of cases
      expect(isTeamPage(generateReq(req.host))).to.be.equal req.expected
    done()


describe 'helpers::isAddressValid', ->

  it 'should resolve public hostnames and allow', (done) ->
    isAddressValid 'http://google.com/test', (err) ->
      expect(err).to.not.exist
      done()

  it 'should deny private IPs (10.0.0.1)', (done) ->
    isAddressValid '10.0.0.1', (err) ->
      expect(err).to.exist
      expect(err.type).to.be.equal 'PRIVATE_IP'
      done()

  it 'should deny private IPs (127.0.0.1)', (done) ->
    isAddressValid '127.0.0.1', (err) ->
      expect(err).to.exist
      expect(err.type).to.be.equal 'PRIVATE_IP'
      done()

  it 'should deny private IPs (192.168.1.1)', (done) ->
    isAddressValid '192.168.1.1', (err) ->
      expect(err).to.exist
      expect(err.type).to.be.equal 'PRIVATE_IP'
      done()

  it 'should allow public IPs', (done) ->
    isAddressValid '8.8.8.8:3000', (err) ->
      expect(err).to.not.exist
      done()

  it 'should deny wrong addresses', (done) ->
    isAddressValid 'somerandomaddress', (err) ->
      expect(err).to.exist
      expect(err.type).to.be.equal 'NOT_REACHABLE'
      done()

  it 'should support query strings on addresses', (done) ->
    isAddressValid 'yahoo.com?test=foo&bar', (err) ->
      expect(err).to.not.exist
      done()
