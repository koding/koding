kd = require 'kd'
contentModal = require 'app/components/contentModal'

module.exports = class KodingListView extends kd.ListView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'koding-listview', options.cssClass

    super options, data


  askForConfirm: (options) ->

    { title, description, callback } = options

    if not title or not description
      return kd.warn 'You should pass title or description for confirm modal'

    modal = new contentModal
      width : 400
      overlay : yes
      cssClass : 'askForConfirm'
      title : title
      content : "<h2>#{description}</h2>"
      buttons :
        cancel      :
          title     : 'Cancel'
          callback  : ->
            modal.destroy()
            callback { status : no }
        ok          :
          title     : 'Yes'
          cssClass  : 'solid red medium'
          callback  : ->
            callback { status : yes, modal }

