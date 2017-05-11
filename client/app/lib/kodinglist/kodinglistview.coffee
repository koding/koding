kd = require 'kd'
ContentModal = require 'app/components/contentModal'

module.exports = class KodingListView extends kd.ListView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'koding-listview', options.cssClass

    super options, data


  askForConfirm: (options) ->

    { title, description, callback } = options

    if not title or not description
      return kd.warn 'You should pass title or description for confirm modal'

    modal = new ContentModal
      width : 400
      overlay : yes
      cssClass : 'askForConfirm content-modal'
      title : title
      content : "<h2>#{description}</h2>"
      buttons :
        cancel      :
          cssClass  : 'solid medium'
          title     : 'Cancel'
          callback  : ->
            modal.destroy()
            callback { status : no }
        ok          :
          title     : 'Yes'
          cssClass  : 'solid medium'
          callback  : ->
            callback { status : yes, modal }


  mouseDown: ->

    kd.singletons.windowController.setKeyView this
    return no


  destroy: ->

    kd.singletons.windowController.revertKeyView this
    super
