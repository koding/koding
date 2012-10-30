class EmbedBox extends KDView
  constructor:(options, data)->
    super options,data

    @setClass "link-embed-box"

    @hide()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  clearEmbed:=>
    @$("div.embed").remove()
    @hide()

  fetchEmbed:(url,options,callback=noop)=>

    requirejs ["http://scripts.embed.ly/jquery.embedly.min.js"], (embedly)=>

      embedlyOptions = {
        key      : "e8d8b766e2864a129f9e53460d520115"
        maxWidth : 560
        width    : 560
        wmode    : "transparent"
      }

      $.extend yes, embedlyOptions, options

      $.embedly url, embedlyOptions, (oembed, dict)=>
        callback oembed

  populateEmbed:(data)=>
    @$("div.link-embed").html data?.code

  embedUrl:(url,options={},callback=noop)=>
    @clearEmbed()
    @fetchEmbed url, options, (data)=>
      @populateEmbed data
      @show()
      log "cb is",callback
      callback data

  pistachio:->
    """
      <div class="link-embed"></div>
    """