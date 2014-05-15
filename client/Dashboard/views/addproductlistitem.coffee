class GroupAddProductListItem extends KDListItemView

  JView.mixin @prototype

  viewAppended: ->
    options = @getOptions()

    @qtyView = new KDInputView
      attributes    :
        size        : 4

    JView::viewAppended.call this

  setQuantity: (qty) ->
    @qtyView.setValue qty

  pistachio:->
    """
    {strong{ #(title) }}
    {{ @utils.formatMoney #(feeAmount) / 100 }}
    <div class="fr">
      <strong>QTY:</strong>
      {{> @qtyView}}
    </div>
    """