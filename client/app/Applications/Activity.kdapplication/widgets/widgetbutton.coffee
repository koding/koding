# class WidgetButton extends KDButtonViewWithMenu

#   constructor:(options, data)->

#     options.itemChildClass = WidgetButtonItem

#     super options, data


#   setTitle:(title)->
#     @$('button').append("<span class='title'>#{title}</span>")

#   click:(event)->

#     @contextMenu event
#     return no

#   decorateButton:(tabName, title)->
#     @$('button span.icon').attr "class","icon #{tabName}"
#     @$('button span.title').text title

# class WidgetButtonItem extends KDCustomHTMLView

#   constructor: (options = {}, data) ->

#     options.tagName = "a"
#     super

#     @setClass "#{@utils.slugify(data.type)}"

#   viewAppended: JView::viewAppended

#   pistachio : ->
#     "<span class='icon'/>{{ #(title)}}"

class WidgetButton extends KDCustomHTMLView

  constructor:(options)->
    options.cssClass = "update-type-select-icons"
    super options

  viewAppended:->
    {items, delegate} = @getOptions()

    for title, content of items
      @addSubView icon = new KDCustomHTMLView
        cssClass       : "#{@utils.slugify(content.type)}"
        _type          : content.type
        _title         : title
        click          : ->
          delegate.changeTab @getOption("_type"), @getOption("_title")

      icon.setClass "hidden" if content.disabled


