kd = require 'kd'
KDListItemView = kd.ListItemView
KDView = kd.View
GroupProductView = require './groupproductview'
JView = require 'app/jview'


module.exports = class GroupProductListItem extends KDListItemView

  JView.mixin @prototype

  viewAppended: ->
    product = @getData()

    @productView = new GroupProductView {}, product

    @controls ?= new KDView

    JView::viewAppended.call this

  setControls: (controlsView) ->
    @controls ?= new KDView
    @controls.addSubView controlsView

  activate: ->
    @setClass 'active'

  deactivate: ->
    @unsetClass 'active'

  disable: ->
    @setClass 'disabled'
    view.disable?()  for view in @controls.subViews

  enable: ->
    @unsetClass 'disabled'
    view.enable?()  for view in @controls.subViews

  pistachio: ->
    """
    <div class="product-item">
      {{> @productView}}
      {{> @controls}}
    </div>
    """


