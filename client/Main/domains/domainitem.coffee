class DomainItem extends KDListItemView

  constructor:(options = {}, data)->

    options.type = 'domain'
    super options, data

  partial: ->

    { domain } = @getData()
    return "#{domain} <span></span>"
