{ config } = require 'globals'
{ Status } = require 'app/redux/modules/payment/constants'

module.exports = getGroupStatus = (group) ->

  switch
    # if stripe token is not set don't try to validate.
    # This is mainly for default environment
    when not config.stripe.token then Status.ACTIVE

    # This state is to identify teams before payment update.
    # This state is only possible for members.
    when not group.payment then Status.NEEDS_UPGRADE

    # for the people who haven't logged in after we activated new payment
    # system.
    when not group.payment.customer then Status.NEEDS_UPGRADE

    # This state is to identify teams without credit cards.
    # With latest changes we are forcing users to enter a cc.
    when not group.payment.customer.hasCard then Status.NEEDS_UPGRADE

    # for the people who haven't logged in after we activated new payment
    # system.
    when not group.payment.subscription then Status.NEEDS_UPGRADE

    # This can only happen when a team fails to enter a credit card or we
    # couldn't charge the credit card they entered.
    when not group.payment.subscription.status then Status.CANCELED

    # happy path. use info from group.
    else group.payment.subscription.status
