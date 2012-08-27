class NFinderItemRenameView extends JView

  constructor:(options, data)->

    super
    @setClass "rename-container"
    @input = new NFinderRenameInput
      defaultValue  : data.name
      type          : "text"
      callback      : (newValue)=> @emit "FinderRenameConfirmation", newValue
    @getSingleton("windowController").addLayer @input
    
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
class NFinderRenameInput extends KDHitEnterInputView

  click    : -> no
  dblClick : -> no