class DomainItem extends KDListItemView

  constructor:(options = {}, data)->

    options.type = 'domain'
    super options, data

  viewAppended: ->

    { domain } = @getData()
    domainLink = "<a href='http://#{domain}' target='_blank'>#{domain}</a>"

    @addSubView new CustomLinkView
      title  : domain
      href   : "http://#{domain}"
      target : '_blank'

    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'remove-domain'
      click    : =>
        @getDelegate().emit 'DeleteDomainRequested', this

    @addSubView new KodingSwitch
      cssClass : 'tiny'
      defaultValue : yes
