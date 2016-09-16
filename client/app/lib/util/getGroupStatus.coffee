
module.exports = getGroupStatus = (group) ->

  # return 'unlimited'  if global.config.environment is 'default'

  return 'no payment'  unless group.payment

  return 'no subscription'  unless group.payment.subscription

  return 'no status'  unless group.payment.subscription.status

  return group.payment.subscription.status


