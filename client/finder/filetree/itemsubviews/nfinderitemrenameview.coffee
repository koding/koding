JView              = require '../../../core/jview'
NFinderRenameInput = require '../../nfinderrenameinput'


class NFinderItemRenameView extends JView

  constructor:(options, data)->

    super
    @setClass "rename-container"
    @input = new NFinderRenameInput
      defaultValue  : data.name
      type          : "text"
      callback      : (newValue)=> @emit "FinderRenameConfirmation", newValue
      keyup         : (event)=>
        @emit "FinderRenameConfirmation", (data.name) if event.which is 27

    KD.getSingleton("windowController").addLayer @input

    @cancel = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : '#'
        title       : 'Cancel'
      cssClass      : 'cancel'
      click         : => @emit "FinderRenameConfirmation", (data.name)

  pistachio:->

    """
    {{> @input}}
    {{> @cancel}}
    """



module.exports = NFinderItemRenameView
