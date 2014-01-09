class VmPlanView extends JView
  pistachio: ->
    """
    {h4{#(title) or #(plan.title)}}
    {strong{ @utils.formatMoney #(feeAmount) / 100 }}
    """