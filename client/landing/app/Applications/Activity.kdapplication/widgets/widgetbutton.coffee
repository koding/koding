class WidgetButton extends KDButtonViewWithMenu

  constructor:(options, data)->

    options.itemChildClass = WidgetButtonItem

    super options, data


  setTitle:(title)->
    @$('button').append("<span class='title'>#{title}</span>")

  click:(event)->

    @contextMenu event
    return no

  decorateButton:(tabName, title)->
    @$('button span.icon').attr "class","icon #{tabName}"
    @$('button span.title').text title

class WidgetButtonItem extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName = "a"
    super

    @setClass "#{@utils.slugify(data.type)}"

  viewAppended: JView::viewAppended

  pistachio : ->
    "<span class='icon'/>{{ #(title)}}"