{ testCsrfToken }                       = require '../../testhelper/handler'
{ generateGoogleCallbackRequestParams } = require '../../testhelper/googlecallbackhelper'


runTests = -> describe 'server.handlers.google_callback', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateGoogleCallbackRequestParams, 'get', done


runTests()
