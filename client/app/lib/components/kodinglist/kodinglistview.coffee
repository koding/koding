kd            = require 'kd'
KDListView    = kd.ListView
KDModalView   = kd.ModalView


module.exports = class KodingListView extends KDListView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'koding-listview', options.cssClass

    super options, data


  askForConfirm: (options) ->

    { title, description, callback, type, cssClass } = options

    if not title or not description
      return kd.warn 'You should pass title or description for confirm modal'

    modal = KDModalView.confirm
      title       : title
      description : description
      ok          :
        title     : 'Yes'
        callback  : ->
          callback { status : yes, modal }
      cancel      :
        title     : 'Cancel'
        callback  : ->
          modal.destroy()
          callback { status : no }
