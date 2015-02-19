kd = require 'kd'
KDView = kd.View
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
KDLoaderView = kd.LoaderView

module.exports = class StackProgressModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry "stack-progress", options.cssClass
    options.overlay  ?= yes
    options.width   or= 400

    super options, data

    @createItems()
    @showLoader @items.first

  createItems: ->
    @items = []

    for section, items of @getData()
      @addSubView new KDCustomHTMLView
        tagName : "h4"
        partial : section

      for item in items
        itemView   = new KDCustomHTMLView
          cssClass : "item"
          partial  : item

        itemView.addSubView itemView.loader  = new KDLoaderView
          size     :
            width  : 16

        itemView.addSubView itemView.success = new KDView
          cssClass : "success hidden"

        itemView.addSubView itemView.error   = new KDView
          cssClass : "error hidden"

        @items.push itemView
        @addSubView itemView

  showLoader: (item) ->
    @activeItem = item
    item?.loader.show()

  next: ->
    index = @items.indexOf @activeItem
    @activeItem.loader.hide()
    @activeItem.success?.unsetClass "hidden"

    @showLoader @items[index + 1]

  error: ->
    @activeItem.success.destroy()
    @activeItem.error.show()
