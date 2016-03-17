kd            = require 'kd'
KDListView    = kd.ListView
KDModalView   = kd.ModalView


module.exports = class KodingListView extends KDListView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'koding-listview', options.cssClass

    super options, data


  askForConfirm: (options) ->

    { title, description, item, callback, type } = options

    modal = KDModalView.confirm
      title       : title       or "Remove #{type.toLowerCase()}"
      description : description or 'Do you want to remove it?'
      ok          :
        title     : 'Yes'
        callback  : ->
          callback { status : yes, modal }
      cancel      :
        title     : 'Cancel'
        callback  : ->
          modal.destroy()
          callback { status : no }
