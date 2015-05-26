kd                 = require 'kd'
hljs               = require 'highlight.js'
KDListView         = kd.ListView
KDModalView        = kd.ModalView
KDOverlayView      = kd.OverlayView

showError          = require 'app/util/showError'


module.exports = class StackTemplateList extends KDListView

  constructor: (options = {}, data) ->

    options.tagName   ?= "ul"

    super options, data


  # TODO Check if the template is in use and warn user about that! ~ GG
  deleteItem: (item) ->

    stack = item.getData()

    # Since KDModalView.confirm not passing overlay options
    # to the base class (KDModalView) I had to do this hack
    # Remove this when issue fixed in Framework ~ GG
    overlay = new KDOverlayView cssClass: 'second-overlay'

    modal   = KDModalView.confirm
      title       : 'Remove stack'
      description : 'Do you want to remove ?'
      ok          :
        title     : 'Yes'
        callback  :  => stack.delete (err) =>
          modal.destroy()
          @emit 'ItemDeleted', item  unless showError err

    modal.once   'KDObjectWillBeDestroyed', overlay.bound 'destroy'
    overlay.once 'click',                   modal.bound   'destroy'

    return modal
