class NFinderItemRenameView extends JView

  constructor:(options, data)->

    super
    @setClass "rename-container"
    @input = new KDHitEnterInputView
      defaultValue  : data.name
      type          : "text"
      mousedown     : (pubInst, event)->
        log event,">>>>"
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
