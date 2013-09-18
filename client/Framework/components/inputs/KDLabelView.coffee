class KDLabelView extends KDView
  constructor:(options)->
    @setTitle(options.title)        if options?.title?
    super options

  setDomElement:(cssClass)->
    @domElement = $ "<label class='kdlabel #{cssClass}'>#{@getTitle()}</label>"

  setTitle:(title)->
    @labelTitle = title or ''

  updateTitle: (title) ->
    @setTitle title
    @$().html title

  getTitle:-> @labelTitle
