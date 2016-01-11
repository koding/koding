kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
JView = require 'app/jview'
CustomLinkView = require 'app/customlinkview'
proxifyUrl = require 'app/util/proxifyUrl'


module.exports = class EmbedBoxLinkViewImage extends CustomLinkView

  JView.mixin @prototype

  constructor:(options={}, data)->
    options.href   = data.link_url or data.link_embed?.url
    options.target = "_blank"

    imageOptions         = options.imageOptions or {}
    imageOptions.width  ?= 100
    imageOptions.height ?= 100
    imageOptions.crop   ?= yes
    imageOptions.grow   ?= yes

    super options, data

    oembed = @getData().link_embed

    @imageLink    = proxifyUrl oembed.images?[0]?.url, imageOptions
    altSuffix     = if oembed.author_name then " by #{oembed.author_name}" else ''
    @imageAltText = oembed.title + altSuffix

    @imageView = new KDCustomHTMLView
      tagName      : 'img'
      cssClass      : 'thumb'
      bind         : 'error'
      error        : @bound 'hide'
      attributes   :
        src        : @imageLink
        alt        : @imageAltText
        title      : @imageAltText

  # this will get called from the image-switch click events to update the preview
  # images when browsing the available embed links
  setSrc: (src) ->
    @imageView.getElement().src = src

  viewAppended: JView::viewAppended

  pistachio:->
    """
      {{> @imageView}}
    """
