kd   = require 'kd'
_    = require 'lodash'
Pane = require './pane'

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


  viewAppended: ->

    @modalTabs.on 'PaneDidShow', => kd.utils.defer @bound '_windowDidResize'
    @_windowDidResize()


  _windowDidResize: ->

    {innerHeight} = window
    titleHeight   = @$('.kdmodal-title').outerHeight no
    handleHeight  = @$('.kdtabhandlecontainer').outerHeight no
    headHeight    = @$('.list-head').outerHeight no
    # 150px bc it looks good :) padding/margin etc. - SY
    maxHeight     = Math.min 240, innerHeight - 150 - titleHeight - handleHeight - headHeight
    @$('.kdmodal-content .shortcuts-pane .kdscrollview').css {maxHeight}

    @setPositions()
