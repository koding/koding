kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
EmbedBoxLinkViewContent = require './embedboxlinkviewcontent'
EmbedBoxLinkViewImage = require './embedboxlinkviewimage'
EmbedBoxLinkViewImageSwitch = require './embedboxlinkviewimageswitch'


module.exports = class EmbedBoxLinkView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'embed embed-link-view custom-link clearfix', options.cssClass

    super options, data

    @addSubView @embedContent = new EmbedBoxLinkViewContent
      cssClass  : 'preview-text'
      delegate  : this
    , data

    @addSubView @embedImage = if data.link_embed?.images?[0]?
      @setClass 'with-image'
      new EmbedBoxLinkViewImage
        cssClass     : 'preview-image'
        delegate     : this
        imageOptions :
          width      : 100
          height     : 100
          crop       : yes
          grow       : yes
      , data
    else new KDCustomHTMLView 'hidden'

    @addSubView @embedImageSwitch = new EmbedBoxLinkViewImageSwitch
      cssClass : 'preview-link-pager'
      delegate : this
    , data
