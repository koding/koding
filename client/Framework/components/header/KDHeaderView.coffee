class KDHeaderView extends KDView
  constructor:(options,data)->
    options = options ? {}
    options.type = options.type ? "default"
    super options,data

    if options.title?
      if @lazy
      then @updateTitle options.title
      else @setTitle options.title

  setTitle:(title)->
    @getDomElement().append "<span>#{title}</span>"

  updateTitle: (title) ->
    @$().find('span').html title

  setDomElement:(cssClass = "")->
    type    = @getOption "type"
    tagName = switch type
      when "big"    then "h1"
      when "medium" then "h2"
      when "small"  then "h3"
      else "h4"
    @setOption "tagName", tagName
    @setOption "cssClass", @utils.curryCssClass "kdheaderview", @getOption cssClass

    super
