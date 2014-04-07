class LinkMenuItemView extends JView

  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'links-menu-item', options.cssClass
    super options, data

  pistachio:->
    {title, link} = @getData()
    """<a href="#{link}" target="_blank"><span>#{title}</span></a>"""