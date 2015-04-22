kd = require 'kd'
KDListItemView = kd.ListItemView
JView = require 'app/jview'


module.exports = class GroupChildProductListItem extends KDListItemView

  JView.mixin @prototype

  pistachio: ->
    """
    {.fl{ #(product.title) }}
    <span class="fr">x{{ #(quantity) }}</span>
    """

