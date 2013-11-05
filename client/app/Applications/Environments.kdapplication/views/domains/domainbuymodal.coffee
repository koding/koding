class DomainBuyModal extends BuyModal

  constructor: (options = {}, data) ->
    options.title ?= "Register <em>#{options.domain}</em>"
    super options, data
