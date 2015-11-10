{ testCsrfToken }                       = require '../../testhelper/handler'
{ generateGithubCallbackRequestParams } = require '../../testhelper/githubcallbackhelper'


runTests = -> describe 'server.handlers.github_callback', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateGithubCallbackRequestParams, 'get', done


runTests()

