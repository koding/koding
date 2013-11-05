class DomainBuyItem extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry "domain-buy-items", options.cssClass

    data.price = (parseFloat data.price).toFixed 2
    super options, data

    selectOptions = \
      ({title: "#{i} year for $#{(@getData().price * i).toFixed 2}", \
        value: i} for i in [1..5])

    @yearBox = new KDSelectBox {name:'year', selectOptions}

    @buyButton = new KDButtonView
      title    : "Buy"
      style    : "clean-gray"
      callback : => @parent.emit 'BuyButtonClicked', this

  viewAppended: ->
    JView::viewAppended.call this

  pistachio:->
    """
      {h1{#(domain)}}
      {{> @yearBox}}
      {{> @buyButton}}
    """