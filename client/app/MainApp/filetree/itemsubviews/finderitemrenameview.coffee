class NFinderItemRenameView extends JView

  constructor:(options, data)->

    super
    @setClass "rename-container"
    @input = new KDHitEnterInputView
      defaultValue  : data.name
      type          : "text"
      callback      : (newValue)=>
        @propagateEvent KDEventType : "FinderRenameConfirmation", newValue

    @cancel = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : '#'
        title       : 'Cancel'
      cssClass      : 'cancel'
      click         : =>
        @propagateEvent KDEventType : "FinderRenameConfirmation", (data.name)

  show:->
    
    super
    @input.$().focus()

  pistachio:->
    
    """
    {{> @input}}  
    {{> @cancel}}
    """
