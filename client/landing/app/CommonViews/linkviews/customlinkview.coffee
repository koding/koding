class CustomLinkView extends KDCustomHTMLView

  constructor:(options = {}, data = {})->

    options.tagName or= 'a'
    options.cssClass  = KD.utils.curryCssClass 'custom-link-view', options.cssClass
    data.title        = options.title

    if options.icon
      options.icon           or= {}
      options.icon.placement or= 'left'
      options.icon.cssClass  or= ''

    super options, data

    if options.icon
      options.icon.tagName  = 'span'
      options.icon.cssClass = KD.utils.curryCssClass "icon", options.icon.cssClass

      @icon = new KDCustomHTMLView options.icon

  viewAppended : JView::viewAppended

  pistachio:->

    {icon, title} = @getOptions()

    tmpl = "{{> @icon}}"

    if icon and title
      if icon.placement is 'left'
        tmpl += "{span.title{ #(title)}}"
      else
        tmpl = "{span.title{ #(title)}}" + tmpl
    else if not icon and title
      tmpl = "{span.title{ #(title)}}"

    return tmpl

###
Samples:

    # icon on the left with a title
    link = new CustomLinkView
      title      : "Edit"
      icon       :
        cssClass : 'edit'

    outputs: <a>[icon]Edit</a>

    # icon on the right with a title
    link = new CustomLinkView
      title       : 'Delete'
      icon        :
        cssClass  : 'delete'
        placement : 'right'

    outputs: <a>Delete[icon]</a>

    # no icon just a title
    link = new CustomLinkView
      title    : 'without icon'

    outputs: <a>without icon</a>

    # just with an icon
    link = new CustomLinkView
      icon        :
        cssClass  : 'delete'

    outputs: <a>[icon]</a>

###