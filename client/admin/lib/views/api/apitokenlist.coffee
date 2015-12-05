kd                    = require 'kd'
showError             = require 'app/util/showError'
KDListView            = kd.ListView
KDModalView           = kd.ModalView
KDOverlayView         = kd.OverlayView
ApiTokenItemView      = require './apitokenitemview'


module.exports = class ApiTokenList extends KDListView

  constructor: (options = {}, data) ->
    options.wrapper   ?= yes
    options.itemClass ?= ApiTokenItemView

    super options, data


  deleteItem: (item) ->

    stack = item.getData()

    overlay = new KDOverlayView cssClass: 'second-overlay'

    modal   = KDModalView.confirm
      title       : 'Remove Api Token'
      description : 'Do you want to remove ?'
      ok          :
        title     : 'Yes'
        callback  : =>
          apiToken = item.data
          apiToken.remove (err) =>
            modal.destroy()
            @emit 'ItemDeleted', item  unless showError err

    modal.once   'KDObjectWillBeDestroyed', overlay.bound 'destroy'
    overlay.once 'click',                   modal.bound   'destroy'

    return modal

