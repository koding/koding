class ModalWorkspaceItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.attributes = {}

    super


  pistachio: ->
    """
    {{ #(slug) }}
    """

