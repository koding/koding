class EditorSaveButton extends KDButtonViewWithMenu
  performSaveFileAs: ->
    @getAceView().handleEvent type: 'RequestFileSaveAs'

  getAceView: ->
    @getDelegate().getDelegate()
    
  click:->
    # this is NOT a good way to be doing this. need to figure it out later.
    # we can't have the save button or dropdown working when there's a split coming from the StartTab
    # but we can't destroy the editor that's not really supposed to be there, either.
    return if @parent.parent.parent.getActiveCodeField().getData 'isFile' is no
    super
