class SubscriptionGaugeItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    {product, @subscription} = data
    @productKey = product.planCode

    @progressBar  = new KDProgressBarView
      determinate : yes
      initial     : @calculateUsageRatio()
      title       : @getProgressBarTitle()

    @subscription.on "update", @bound "updateProgressBar"

  updateProgressBar: ->
    @progressBar.updateBar @calculateUsageRatio(), "%", @getProgressBarTitle()

  getProgressBarTitle: ->
    {usage, quantities} = @subscription
    "#{usage[@productKey] or 0} / #{quantities[@productKey]}"

  calculateUsageRatio: ->
    {usage, quantities} = @subscription
    ratio = usage[@productKey] / quantities[@productKey]
    ratio = 0  if isNaN ratio
    return ratio * 100

  viewAppended: ->
    {product: {title}} = @getData()
    @setClass KD.utils.slugify title
    @addSubView new KDLabelView {title}
    @addSubView @progressBar
