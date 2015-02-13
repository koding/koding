class EmbedBoxLinkViewAuthor extends KDView

  JView.mixin @prototype

  constructor:(options,data)->
    super options,data

    @hide()  unless data.link_embed?.author_name?

  pistachio:->
    """
    written by <a href="#{@getData().link_embed?.author_url or @getData().author_url or '#'}" target="_blank">#{@getData().link_embed?.author_name or @getData().author_name}</a>
    """
