class DomainItem extends KDListItemView

  constructor:(options = {}, data)->

    options.type = 'domain'
    super options, data

  partial: ->

    { domain } = @getData()
    domainLink = "<a href='http://#{domain}' target='_blank'>#{domain}</a>"
    topDomain  = "#{KD.nick()}.#{KD.config.userSitesDomain}"

    if domain is topDomain
      return domainLink
    else
      return "#{domainLink} <span></span>"

  click: (event)->

    if $(event.target).is 'span'
      @getDelegate().emit 'DeleteDomainRequested', this

