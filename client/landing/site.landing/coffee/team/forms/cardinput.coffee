kd = require 'kd'


module.exports = class CardInput extends kd.View

  constructor: (options = {}, data) ->
    options.cssClass = kd.utils.curry 'login-input-view', options.cssClass

    super options, null

    { label } = @options

    @label = new kd.CustomHTMLView
      tagName: 'label'
      cssClass: 'placeholder-helper'
      partial: label

    @stripeInputElement = new kd.CustomHTMLView


  mountTo: (stripeElement) ->
    stripeElement.mount @stripeInputElement.getElement()


  pistachio: ->
    '''
    {{> @stripeInputElement}}{{> @label}}
    '''

  resetDecoration: ->
    @unsetClass 'validation-error validation-passed'
    @unsetTooltip()


  decorateValidation: (err) ->

    @resetDecoration()

    { stickyTooltip } = @getOptions()

    if err
      @setTooltip
        cssClass  : 'validation-error'
        title     : "<p>#{err}</p>"
        direction : 'left'
        sticky    : yes  if stickyTooltip
        permanent : yes  if stickyTooltip
        offset    :
          top     : 0
          left    : 0
      @tooltip.show()

    else
      @unsetTooltip()

    @setClass if err then 'validation-error' else 'validation-passed'
