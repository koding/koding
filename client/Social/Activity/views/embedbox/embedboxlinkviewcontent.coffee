class EmbedBoxLinkViewContent extends JView

  constructor:(options={},data)->
    super options, data

    contentOptions =
      tagName    : 'a'
      cssClass   : 'preview_text_link'
      attributes :
        href     : data.link_url
        target   : '_blank'

    @embedTitle = new EmbedBoxLinkViewTitle contentOptions, data

    @embedAuthor   = new EmbedBoxLinkViewAuthor cssClass: 'author_info', data
    @embedProvider = new EmbedBoxLinkViewProvider cssClass: 'provider_info', data

    @embedDescription = new EmbedBoxLinkViewDescription contentOptions, data

  pistachio:->
    """
    {{> @embedTitle}}
    {{> @embedAuthor}}
    {{> @embedProvider}}
    {{> @embedDescription}}
    """
