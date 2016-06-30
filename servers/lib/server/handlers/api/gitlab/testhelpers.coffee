
# Export generic testhelpers
testhelpers = require '../../../../../testhelper'

{ expect
  request
  generateUrl
  checkBongoConnectivity
  generateRequestParamsEncodeBody } = testhelpers

utils = require './utils'

testhelpers.gitlabApiUrl = generateUrl { route : '-/api/gitlab' }
testhelpers.gitlabDefaultHeaders = {
  'x-gitlab-event': 'System Hook',
  'x-gitlab-token': utils.GITLAB_TOKEN
}

testhelpers.getSampleDataFor = (event) ->

  return (require './_sampledata')[event] ? { 'event_name': event }

testhelpers.parseEvent = utils.parseEvent

testhelpers.doRequestFor = (event, callback) ->

  { scope, method } = utils.parseEvent event

  params    = generateRequestParamsEncodeBody
    url     : testhelpers.gitlabApiUrl
    headers : testhelpers.gitlabDefaultHeaders
    body    : testhelpers.getSampleDataFor event

  request.post params, callback


module.exports = testhelpers
