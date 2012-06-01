class NFinderItem extends JTreeItemView

  constructor:(options = {},data)->

    options.tagName   or= "li"
    options.type      or= "finderitem"
    super options, data
    @isLoading    = no
    @beingDeleted = no
    @beingEdited  = no
    
    childConstructor = switch data.type
      when "folder"  then NFolderItemView
      when "section" then NSectionItemView
      when "mount"   then NMountItemView
      else NFileItemView
    
    @childView = new childConstructor {}, data
    @childView.$().css "margin-left", (data.depth+1)*10

    @deleteView = new NFinderItemDeleteView
      cssClass : "hidden"
    , data

    @renameView = new NFinderItemRenameView
      cssClass : "hidden"
    , data
    @renameView.$().css "margin-left", ((data.depth+1)*10)+2

    @listenTo
      KDEventTypes       : "FinderDeleteConfirmation"
      listenedToInstance : @deleteView
      callback           : (pubInst, confirmation)=>
        @callback? confirmation
        @resetView()

    @listenTo
      KDEventTypes       : "FinderRenameConfirmation"
      listenedToInstance : @renameView
      callback           : (pubInst, newValue)->
        @callback? newValue
        @resetView()

  showOnly:(view)->
    
    @deleteView.hide()
    @childView.hide()
    @renameView.hide()
    @getSingleton("windowController").setKeyView view
    view.show()

  resetView:(view)->

    @deleteView.hide()
    @renameView.hide()
    @childView.show()
    @beingDeleted = no
    @beingEdited = no
    @callback = null
    @unsetClass "being-deleted being-edited"
  
  confirmDelete:(callback)->
    
    @callback = callback
    @showDeleteView()
    
  showDeleteView:->
    
    @setClass "being-deleted"
    @beingDeleted = yes
    @showOnly @deleteView

  showRenameView:(callback)->
    
    @beingEdited = yes
    @callback = callback
    @setClass "being-edited"
    @showOnly @renameView
    
  pistachio:-> 

    """
    {{> @childView}}
    {{> @deleteView}}
    {{> @renameView}}
    """
