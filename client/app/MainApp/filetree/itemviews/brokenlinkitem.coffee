class NBrokenLinkItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass  or= "broken"
    super options, data
