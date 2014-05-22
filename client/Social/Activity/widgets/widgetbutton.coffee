class WidgetButton extends KDCustomHTMLView

  constructor:(options)->
    options.cssClass = "update-type-select-icons"
    super options

  viewAppended:->
    {items, delegate} = @getOptions()

    for own title, content of items
      @addSubView icon = new KDCustomHTMLView
        cssClass       : "#{@utils.slugify(content.type)}"
        type          : content.type
        title         : title
        click          : ->
          delegate.changeTab @getOption("type"), @getOption("title")

      icon.setClass "hidden" if content.disabled


