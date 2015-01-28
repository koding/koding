class SidebarWorkspaceItem extends KDListItemView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView new KDCustomHTMLView
      partial: data.name


  partial: ->
