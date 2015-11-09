{ testCsrfToken }                         = require '../../testhelper/handler'
{ generateFacebookCallbackRequestParams } = require '../../testhelper/facebookcallbackhelper'


runTests = -> describe 'server.handlers.facebook_callback', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateFacebookCallbackRequestParams, 'get', done


runTests()

