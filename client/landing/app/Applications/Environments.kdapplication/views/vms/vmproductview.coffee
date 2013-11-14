class VmProductView extends KDListItemView

  viewAppended: ->
    @chooseButton = new KDButtonView
      title     : 'Create VM'
      callback  : => @emit 'PackSelected'

    JView::viewAppended.call this

  pistachio: ->
    """
    {h3{ #(title) }}
    {p{ #(description) }}
    {{> @chooseButton}}
    """