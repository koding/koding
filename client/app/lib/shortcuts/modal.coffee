kd   = require 'kd'
_    = require 'lodash'
Pane = require './pane'
facade = require './actions-facade'

module.exports =

class Modal extends kd.ModalViewWithForms

  constructor: (options, @config) ->

    super _.extend

      title    : 'Shortcuts'
      content  : """
        <div class=instructions>
          To change a shortcut, click the key combination, then type the new keys.
        </div>
      """
      cssClass : 'shortcuts-modal'
      overlay  : yes
      width    : 600
      height   : 'auto'

      buttons:
        restore:
          title    : 'Restore Defaults'
          style    : 'solid light-gray medium restore'
          loader   : color: '#444444'
          #callback : -> modal.destroy()

      tabs:
        hideHandleCloseIcons : yes
        enableMoveTabHandle  : no
        forms                : @presentForms()

    , options


  presentForms: ->

    @config.reduce (acc, collection) ->
      acc[collection.title] =
        fields:
          view:
            itemClass  : Pane
            collection : collection
      return acc
    , {}


  destroy: ->

    { shortcuts } = kd.singletons
    shortcuts.unpause()

    facade.dispose()

    super


  viewAppended: ->

    { shortcuts } = kd.singletons
    shortcuts.pause()
