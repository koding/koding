kd            = require 'kd'
KDListView    = kd.ListView
KDModalView   = kd.ModalView
newModal = require 'app/components/newModal'

module.exports = class KodingListView extends KDListView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'koding-listview', options.cssClass

    super options, data


  askForConfirm: (options) ->

    { title, description, callback } = options

    if not title or not description
      return kd.warn 'You should pass title or description for confirm modal'

    modal = new kd.ModalView
      cssClass : 'NewModal'
      width : 400
      overlay : yes

    view = new newModal
      title       : title
      description : description
      cancel      :
        title     : 'Cancel'
        callback  : ->
          modal.destroy()
          callback { status : no }
      ok          :
        title     : 'Yes'
        callback  : ->
          callback { status : yes, modal }

    modal.addSubview view
