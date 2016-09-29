{ defineSchema } = require 'app/redux/helper'

plan = defineSchema 'plan'

subscription = defineSchema 'subscription'

customer = defineSchema 'customer',
  sources:
    data: defineSchema 'sources', []
  subscriptions:
    data: defineSchema 'subscriptions', []

info = defineSchema 'info',
  customer: customer
  subscription: subscription
  expectedPlan: defineSchema 'expectedPlan'


module.exports = {
  plan
  subscription
  customer
  info
}
