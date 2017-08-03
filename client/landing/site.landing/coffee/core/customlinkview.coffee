kd = require 'kd'


module.exports = module.exports = class CustomLinkView extends kd.CustomHTMLView



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

      @icon = new kd.CustomHTMLView options.icon

  pistachio: ->

    options = @getOptions()
    data    = @getData()

    data.title ?= options.attributes.href

    tmpl = '{{> @icon}}'

    if options.icon and data.title
      if options.icon.placement is 'left'
        tmpl += '{span.title{ #(title)}}'
      else
        tmpl = '{span.title{ #(title)}}' + tmpl
    else if not options.icon and data.title
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
