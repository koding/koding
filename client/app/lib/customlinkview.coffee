kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView



module.exports = class CustomLinkView extends KDCustomHTMLView



  constructor: (options = {}, data = {}) ->

    options.tagName or= 'a'
    options.cssClass  = kd.utils.curry 'custom-link-view', options.cssClass
    data.title       ?= options.title

    options.attributes ?= {}
    options.attributes.href     = options.href      if options.href?
    options.attributes.target   = options.target    if options.target?

    if options.icon
      options.icon           or= {}
      options.icon.placement or= 'left'
      options.icon.cssClass  or= ''

    super options, data

    if options.icon
      options.icon.tagName  = 'span'
      options.icon.cssClass = kd.utils.curry 'icon', options.icon.cssClass

      @icon = new KDCustomHTMLView options.icon


  setTitle: (title) ->

    @setOption 'title', title

    @data?.title = title
    @render()


  disable: -> @disabled = yes
  enable: -> @disabled = no


  click: (event) ->

    return no  if @disabled

    super


  pistachio: ->

    options              = @getOptions()
    data                 = @getData()
    { icon, attributes } = options
    { href }             = attributes
    data.title          ?= href  if href isnt '#'
    { title }            = data
    tmpl                 = if icon then '{{> @icon}}' else ''

    if icon and title
      if icon.placement is 'left'
      then tmpl += '{span.title{ #(title)}}'
      else tmpl  = '{span.title{ #(title)}}' + tmpl

    else if not icon and title
      tmpl = '{span.title{ #(title)}}'

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
