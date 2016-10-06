{ expect } = require '../../testhelper'
{ isTeamPage } = require './helpers'


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
