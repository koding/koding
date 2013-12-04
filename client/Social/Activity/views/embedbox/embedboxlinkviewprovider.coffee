class EmbedBoxLinkViewProvider extends KDView

  constructor:(options,data)->
    super options,data

    @hide()  unless data.link_embed?.provider_name?

  viewAppended: JView::viewAppended
  pistachio:->
    """
    <strong>#{@getData().link_embed?.provider_name or @getData().provider_name or 'the internet'}</strong>#{if (@getData().link_embed?.provider_url or @getData().provider_url) then " at <a href=\"" +(@getData().link_embed?.provider_url or @getData().provider_url)+"\" target=\"_blank\">"+(@getData().link_embed?.provider_display or @getData().provider_display)+'</a>' else ''}
    """
