class SidebarWorkspaceItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.cssClass = 'kdlistitemview-main-nav workspace'

    super options, data

    @addSubView new KDCustomHTMLView
      tagName: 'figure'

    @addSubView new CustomLinkView
      title: data.name


  partial: ->
