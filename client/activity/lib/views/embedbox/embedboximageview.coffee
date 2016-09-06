kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
proxifyUrl = require 'app/util/proxifyUrl'


module.exports = class EmbedBoxImageView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    o            = data.link_options or {}
    o.tagName or = 'a'
    o.attributes =
      href       : data.link_url or '#'
      target     : '_blank'
    o.cssClass   = 'embed-image-view'

    super o, data

    oembed = @getData().link_embed
    width  = switch options.type
      when 'activity'       then 550
      when 'comment'        then 498
      when 'privatemessage' then 475
      else                       200

    @addSubView @image  = new KDCustomHTMLView
      tagName     : 'img'
      bind        : 'load'
      attributes  :
        src       : proxifyUrl oembed.images?[0]?.url, {width}
        title     : oembed.title or ''
        width     : "100%"

    @image.on 'load', (event) ->
      kd.singletons.windowController.notifyWindowResizeListeners()
