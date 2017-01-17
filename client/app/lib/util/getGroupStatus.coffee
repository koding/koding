{ config, hasCreditCard } = require 'globals'
{ Status } = require 'app/redux/modules/payment/constants'

module.exports = getGroupStatus = (group) ->

  switch
    # if stripe token is not set don't try to validate.
    # This is mainly for default environment
    when not config.stripe.token then Status.ACTIVE

    # This state is to identify teams without credit cards.
    # With latest changes we are forcing users to enter a cc.
    when not hasCreditCard then Status.NEEDS_UPGRADE

    # This state is to identify teams before payment update.
    # This state is only possible for members.
    when not group.payment then Status.NEEDS_UPGRADE

    # This state should never be here.
    when not group.payment.subscription then Status.UNKNOWN

    # This can only happen when a team fails to enter a credit card or we
    # couldn't charge the credit card they entered.
    when not group.payment.subscription.status then Status.CANCELED

    # happy path. use info from group.
    else group.payment.subscription.status
