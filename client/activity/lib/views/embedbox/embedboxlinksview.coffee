kd = require 'kd'
KDListViewController = kd.ListViewController
KDView = kd.View
EmbedBoxLinksViewItem = require './embedboxlinksviewitem'
JView = require 'app/jview'


module.exports = class EmbedBoxLinksView extends KDView

  JView.mixin @prototype

  constructor: (options = {}, data) ->
    options.cssClass = 'embed-links-container'

    super options,data

    @linkListController = new KDListViewController
      viewOptions :
        cssClass  : 'embed-link-list layout-wrapper'
        delegate  : this
      itemClass   : EmbedBoxLinksViewItem

    @linkListController.on 'ItemSelectionPerformed', (controller, { items }) =>
      items.forEach (item) =>
        @emit 'LinkSelected', item.getData()

    @linkList = @linkListController.getView()

    @hide()

  clearLinks: ->
    @linkListController.removeAllItems()
    @emit 'LinksCleared'

  setActiveLinkIndex: (index) ->
    item = @linkListController.getListItems()[index]
    @linkListController.deselectAllItems()
    @linkListController.selectSingleItem item

  getLinkCount:-> @linkListController.getItemCount()

  addLink: (url) ->
    data = { url }
    @linkListController.addItem data
    @show()  if @linkListController.getItemCount() > 0
    @emit 'LinkAdded', url, data

  removeLink: (url) ->
    @linkListController.getListItems().forEach (item, index) =>
      data = item.getData()
      if data.url is url
        @linkListController.removeItem item
        @emit 'LinkRemoved', { url, index }

  pistachio:->
    """
    {{> @linkList}}
    """


