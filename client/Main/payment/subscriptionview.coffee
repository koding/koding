class SubscriptionView extends JView

  describeSubscription = (quantity, verbPhrase) ->
    """
    Subscription for #{ KD.utils.formatPlural quantity, 'plan' } #{verbPhrase}
    """

  datePattern = "mmmm dS yyyy"

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'subscription clearfix', options.cssClass

    super options, data

    @changeSubscriptionButton = new KDButtonView
      style    : 'solid medium gray'
      cssClass : 'change-subscription-btn'
      title    : 'Change subscription'
      callback : @lazyBound 'emit', 'ChangeSubscriptionRequested', data


  pistachio: ->
    """
      <h4>{{#(planTitle).capitalize()}}</h4>
      {{> @changeSubscriptionButton}}
    """


