class KDHeaderView extends KDView
  constructor:(options,data)->
    options = options ? {}
    options.type = options.type ? "default"
    super options,data
    @setTitle options.title if options.title?

  setTitle:(title)->
    @getDomElement().append "<span>#{title}</span>"

  updateTitle: (title) ->
    @$().find('span').html title

  setDomElement:(cssClass = "")->
    type = @getOptions().type
    switch type
      when "big"    then tag = "h1"
      when "medium" then tag = "h2"
      when "small"  then tag = "h3"
      else tag = "h4"

    @domElement = $ "<#{tag} class='kdview kdheaderview #{cssClass}'></#{tag}>"
