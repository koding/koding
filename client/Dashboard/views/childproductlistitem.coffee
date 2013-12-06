class GroupChildProductListItem extends KDListItemView

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {.fl{ #(product.title) }}
    <span class="fr">x{{ #(quantity) }}</span>
    """