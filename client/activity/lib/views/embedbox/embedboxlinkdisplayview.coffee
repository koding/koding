kd = require 'kd'
KDView = kd.View
EmbedBoxLinkViewContent = require './embedboxlinkviewcontent'
EmbedBoxLinkViewImage = require './embedboxlinkviewimage'


module.exports = class EmbedBoxLinkDisplayView extends KDView

  constructor:(options={}, data)->
    options.cssClass = kd.utils.curry 'embed-link-view clearfix', options.cssClass
    super options, data

    if data?.link_embed?.images?[0]?
      @setClass 'with-image'
      @embedImage = new EmbedBoxLinkViewImage
        cssClass : 'preview-image'
        delegate : this
      ,data

    @embedContent = new EmbedBoxLinkViewContent
      cssClass  : 'preview-text'
      delegate  : this
    , data

  viewAppended : ->
    @addSubView @embedContent
    @addSubView @embedImage if @embedImage
