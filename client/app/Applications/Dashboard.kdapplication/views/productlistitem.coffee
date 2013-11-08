class GroupProductListItem extends KDListItemView

  viewAppended: ->
    product = @getData()

    @productView = new GroupProductView {}, product

    @controls ?= new KDView

    JView::viewAppended.call this

  setControls: (controlsView) ->
    @controls ?= new KDView
    @controls.addSubView controlsView

  pistachio: ->
    """
    <div class="product-item">
      {{> @productView}}
      {{> @controls}}
    </div>
    <hr>
    """