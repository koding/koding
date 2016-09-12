getGroupStatus = require './getGroupStatus'

expiredStatuses = ['expired', 'past_due', 'canceled']

module.exports = isGroupDisabled = (group) ->

  status = getGroupStatus group

  status and status in expiredStatuses
