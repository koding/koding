class VmProductView extends JView
  constructor: (options = {}, data) ->
    super options, data

  formatCurrency: (cents) -> ( cents / 100 ).toFixed 2

  pistachio: ->
    """
    <h3>{{ #(title) }}</h3>
    <div>
      <span class="dollar">$</span>
      {span{ @formatCurrency #(feeMonthly) }}
      <span class="per-month">/ mo</span>
    </div>
    """