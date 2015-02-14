JView = require '../jview'
kd = require 'kd'
formatMoney = require '../util/formatMoney'
PlanProductListView = require './planproductlistview'

module.exports = class GenericPlanView extends JView

  constructor: (options = {}, data = {} ) ->
    options.cssClass     = kd.utils.curry "generic-plan-view", options.cssClass
    options.hiddenPrice ?= no
    super options, data

  pistachio: ->
    data = @getData()
    {planOptions, hiddenPrice} = @getOptions()
    total = if planOptions?.total then planOptions.total else data.feeAmount
    total = formatMoney total / 100
    @productList = new PlanProductListView {planOptions}, data

    """
    {h4{#(description) or #(plan.description)}}
    {{> @productList}}
    <span class="price#{if hiddenPrice then ' hidden' else ''}">#{total}</span>
    """
