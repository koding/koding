kd                    = require 'kd'
KDListView            = kd.ListView
KDModalView           = kd.ModalView
KDOverlayView         = kd.OverlayView

hljs                  = require 'highlight.js'
showError             = require 'app/util/showError'

StackTemplateListItem = require './stacktemplatelistitem'


module.exports = class StackTemplateList extends KDListView

  constructor: (options = {}, data) ->

    options.itemClass ?= StackTemplateListItem

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


  showItemContent: (item) ->

    stackTemplate = item.getData()

    try
      content = JSON.stringify stackTemplate, null, 2
    catch e
      kd.warn e; kd.log data
      return new KDNotificationView
        title: "An error occurred"

    cred = hljs.highlight('json', content).value

    new KDModalView
      title          : stackTemplate.title
      subtitle       : stackTemplate.modifiedAt
      cssClass       : 'has-markdown'
      overlay        : yes
      overlayOptions : cssClass : 'second-overlay'
      content        : "<pre><code>#{cred}</code></pre>"
