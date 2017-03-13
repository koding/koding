getGroup = require './getGroup'
getGroupStatus = require './getGroupStatus'

{ Status } = require 'app/redux/modules/payment/constants'

allowedStatuses = [
  Status.TRIALING
  Status.EXPIRING
  Status.ACTIVE
]

module.exports = isGroupDisabled = (group) ->

  group ?= getGroup()
  status = getGroupStatus group

  isAllowed = status and status in allowedStatuses

  return not isAllowed
