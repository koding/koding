
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

module.exports = testhelpers
