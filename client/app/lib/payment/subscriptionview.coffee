kd = require 'kd'
JView = require '../jview'


module.exports = class SubscriptionView extends JView

  describeSubscription = (quantity, verbPhrase) ->
    """
    Subscription for #{ kd.utils.formatPlural quantity, 'plan' } #{verbPhrase}
    """

  datePattern = "mmmm dS yyyy"

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'subscription clearfix', options.cssClass

    super options, data


  pistachio: ->
    """
      <h4>{{#(planTitle).capitalize()}}</h4>
    """




