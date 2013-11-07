class GroupProductView extends JView

  constructor: (options = {}, data) ->
    options.tagName ?= 'span'
    super options, data

  prepareData: ->
    product = @getData()

    title     = product.title
    price     = @utils.formatMoney product.feeAmount / 100
    displayPrice  =
      if product.priceIsVolatile
      then '<span class="price-volatile">(price is volatile)</span>'
      else "<span class=\"price\">#{ price }</span>"

    subscriptionType =
      if product.subscriptionType is 'single'
      then "Single payment"
      else if product.feeUnit is 'months'
        switch product.feeInterval
          when 1        then "monthly"
          when 3        then "every 3 months"
          when 6        then "every 6 months"
          when 12       then "yearly"
          when 12 * 2   then "every 2 years"
          when 12 * 5   then "every 5 years"
          else               "every #{ product.feeInterval } months"
      else '' # we don't support renewals by the day (yet)

    { title, price, displayPrice, subscriptionType }

  pistachio: ->
    { title, displayPrice, subscriptionType } = @prepareData()

    """
    #{title} — #{displayPrice} #{subscriptionType}
    """
