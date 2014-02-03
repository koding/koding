class VmPlanView extends JView
  constructor: (options = {}, data = {} ) ->
    options.cssClass = KD.utils.curry "vm-plan-view", options.cssClass
    super options, data

  pistachio: ->
    {planOptions} = @getOptions()
    total = if planOptions?.total then planOptions.total else @getData().feeAmount
    total = KD.utils.formatMoney total / 100
    """
    {h4{#(title) or #(plan.title)}}
    <span class="price">#{total}</span>
    """
