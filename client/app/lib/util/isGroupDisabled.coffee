getGroupStatus = require './getGroupStatus'

{ Status } = require 'app/redux/modules/payment/constants'

expiredStatuses = [
  Status.EXPIRED
  Status.PAST_DUE
  Status.CANCELED
]

module.exports = isGroupDisabled = (group) ->

  status = getGroupStatus group

  status and status in expiredStatuses
