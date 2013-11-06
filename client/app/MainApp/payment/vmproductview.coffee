class VmProductView extends JView
  constructor: (options = {}, data) ->
    super options, data

  pistachio: ->
    """
    <h3>{{ #(title) }}</h3>
    <div>
      <span class="dollar">$</span>
      {span{ @utils.formatMoney #(feeAmount) }}
      <span class="per-month">/ mo</span>
    </div>
    """