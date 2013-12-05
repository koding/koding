class EmbedBoxLinkViewProvider extends KDView

  constructor:(options,data)->
    super options,data

    @hide()  unless data.link_embed?.provider_name?

  viewAppended: JView::viewAppended
  pistachio:->
    data = @getData()

    {link_embed, provider_name, provider_url, provider_display} = data

    link_embed       or= {}
    provider_name    or= link_embed.provider_name    or ''
    provider_url     or= link_embed.provider_url
    provider_display or= link_embed.provider_display or ''

    if provider_url
    then provider_link = "at <a href='#{provider_url}' target='_blank'>#{provider_display}</a>"
    else provider_link = ''

    "<strong>#{provider_name}</strong>#{provider_link}"
