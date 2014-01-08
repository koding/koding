class FatihListItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.tagName = "li"

    super options, data

    list     = @getDelegate()
    @plugin  = list.getDelegate()

  click: (event) ->
    @plugin.emit "FatihPluginListItemClicked", @getData()
    @plugin.fatihView.destroy()

  partial: ->
    """
      <span class="icon #{@plugin.getOptions().iconCssClass}"></span>
      <span class="name">#{@getData().title}</span>
    """