class GroupChildProductListItem extends KDListItemView

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {{ #(product.title) }}
    <span class="qty">x{{ #(quantity) }}</span>
    """