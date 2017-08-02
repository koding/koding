kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView

NFinderRenameInput = require './nfinderrenameinput'
module.exports = class NFinderItemRenameView extends kd.View

  constructor: (options, data) ->

    super
    @setClass 'rename-container'
    @input = new NFinderRenameInput
      defaultValue  : data.name
      type          : 'text'
      callback      : (newValue) => @emit 'FinderRenameConfirmation', newValue
      keyup         : (event) =>
        @emit 'FinderRenameConfirmation', (data.name) if event.which is 27

    kd.getSingleton('windowController').addLayer @input

    @cancel = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : '#'
        title       : 'Cancel'
      cssClass      : 'cancel'
      click         : => @emit 'FinderRenameConfirmation', (data.name)

  pistachio: ->

    '''
    {{> @input}}
    {{> @cancel}}
    '''
