class SubscriptionGaugeItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    {@productKey, @subscription} = data

    @progressBar  = new KDProgressBarView
      determinate : yes
      initial     : @calculateUsageRatio()

    @subscription.on "update", @bound "updateProgressBar"

  updateProgressBar: ->
    {usage, quantities} = @subscription
    @progressBar.updateBar @calculateUsageRatio(), "%", "#{usage[@productKey] or 0} / #{quantities[@productKey]}"

  calculateUsageRatio: ->
    {usage, quantities} = @subscription
    ratio = usage[@productKey] / quantities[@productKey]
    ratio = 0  if isNaN ratio
    return ratio * 100

  viewAppended: ->
    options = targetOptions: selector: planCode: @productKey
    @subscription.plan.fetchProducts null, options, (err, [product]) =>
      return  if KD.showError err
      return KD.showError "Product not found"  unless product
      {title} = product
      @setClass KD.utils.slugify title
      @addSubView new KDLabelView {title}
      @addSubView @progressBar
      @updateProgressBar()
