class DomainItem extends KDListItemView

  constructor:(options = {}, data)->

    options.type = 'domain'
    super options, data


  viewAppended:->

    {domain} = @getData()

    @addSubView new KDCustomHTMLView
      partial : "#{domain} <span></span>"

