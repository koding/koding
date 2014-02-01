class VmProductView extends KDListItemView

  shouldShowControls: ->
    @getOptions().showControls ? yes

  viewAppended: ->
    options = @getOptions()
  
    @chooseButton = new KDButtonView
      title     : 'Create VM'
      callback  : => @emit 'PackSelected'
    
    @chooseButton.hide()  unless @shouldShowControls()

    JView::viewAppended.call this

  pistachio: ->
    """
    {h3{ #(title) }}
    {p{ #(description) or "" }}
    {{> @chooseButton}}
    """