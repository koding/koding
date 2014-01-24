class VmPlanView extends JView
  pistachio: ->
    {planOptions} = @getOptions()
    total = if planOptions?.total then planOptions.total else @getData().feeAmount
    total = KD.utils.formatMoney total / 100
    """
    {h4{#(title) or #(plan.title)}}
    <strong>#{total}</strong>
    """
