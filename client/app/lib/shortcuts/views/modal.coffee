kd            = require 'kd'
_             = require 'underscore'
ShortcutsPane = require './pane'
defaults      = require '../config'

module.exports = class ShortcutsModal extends kd.ModalViewWithForms

  constructor: (options={}, keyconfig) ->

    options =
      title                   : 'Shortcuts'
      cssClass                : 'shortcuts-modal'
      overlay                 : yes
      width                   : 640
      height                  : 'auto'
      buttons                 :
        restore               :
          title               : 'Restore Defaults'
          style               : 'solid light-gray medium'
          loader              : color : '#444444'
          callback            : -> modal.destroy()
        save                  :
          title               : 'Save'
          cssClass            : 'solid green medium'
      tabs                    :
        hideHandleCloseIcons  : yes
        enableMoveTabHandle   : no
        cssClass              : 'shortcuts-tab'
        forms                 : @prepareTabData keyconfig

    super options


  viewAppended: ->

    @modalTabs.on 'PaneDidShow', => kd.utils.defer @bound '_windowDidResize'

    @_windowDidResize()


  prepareTabData: (keyconfig) ->

    forms = {}
    keyconfig.forEach (collection) ->
      displayData = defaults[collection.name]
      forms[displayData.title] =
        fields                :
          view                :
            itemClass         : ShortcutsPane
            description       : displayData.description
            collection        : collection

    return forms


  _windowDidResize: ->

    {innerHeight} = window
    titleHeight   = @$('.kdmodal-title').outerHeight no
    handleHeight  = @$('.kdtabhandlecontainer').outerHeight no
    headHeight    = @$('.list-head').outerHeight no
    # 150px bc it looks good :) padding/margin etc. - SY
    maxHeight     = Math.min 240, innerHeight - 150 - titleHeight - handleHeight - headHeight
    @$('.kdmodal-content .shortcuts-pane .kdscrollview').css {maxHeight}

    @setPositions()
