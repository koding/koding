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
    <p>ctor ligula, nec semper tortor metus ut dolor. Nulla varius vitae leo et ultrices. Cras sagittis vulputate imperdiet. Pellentesque ut varius </p>
    <span class="price">#{total}</span>
    """
