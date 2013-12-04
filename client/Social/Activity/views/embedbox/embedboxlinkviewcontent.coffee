class EmbedBoxLinkViewContent extends JView

  constructor:(options={},data)->
    super options, data

    contentOptions =
      tagName    : 'a'
      cssClass   : 'preview-text-link'
      attributes :
        href     : data.link_url
        target   : '_blank'

    @embedTitle = new EmbedBoxLinkViewTitle contentOptions, data

    @embedAuthor   = new EmbedBoxLinkViewAuthor cssClass: 'author-info', data
    @embedProvider = new EmbedBoxLinkViewProvider cssClass: 'provider-info', data

    @embedDescription = new EmbedBoxLinkViewDescription contentOptions, data

  pistachio:->
    """
    {{> @embedTitle}}
    {{> @embedAuthor}}
    {{> @embedDescription}}
    {{> @embedProvider}}
    """
