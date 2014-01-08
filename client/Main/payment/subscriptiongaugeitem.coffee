class SubscriptionGaugeItem extends KDListItemView
  constructor: (options = {}, data) ->

    super options, data

  partial: ->
    usage = @getData()
    """
    <h3>
      Component:  #{ usage.component.title }
    </h3>
    <p>
      Used:       <strong>#{ usage.usage }</strong>
    </p>
    <p>
      Quota:      <strong>#{ usage.quota }</strong>
    </p>
    <p>
      Ratio:      <strong>#{ usage.usageRatio * 100 }%</strong>
    </p>
    """