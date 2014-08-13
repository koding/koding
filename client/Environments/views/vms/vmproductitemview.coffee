class VmProductItemView extends KDListItemView

  JView.mixin @prototype

  constructor : (options = {}, data = {}) ->
    options.type ?= 'vm-product'

    super options, data

  shouldShowControls: ->
    @getOptions().showControls ? yes

  viewAppended: ->
    options = @getOptions()

    @chooseButton = new KDButtonView
      title     : 'Create VM'
      style     : 'solid green small'
      callback  : => @emit 'PackSelected'

    @chooseButton.hide()  unless @shouldShowControls()

    JView::viewAppended.call this

  pistachio: ->
    """
    {h3{ #(title) }}
    {p{ #(description) or "" }}
    {{> @chooseButton}}
    """
