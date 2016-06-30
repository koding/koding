htmlencode            = require 'htmlencode'
$                     = require 'jquery'
kd                    = require 'kd'
KDView                = kd.View
OnboardingMetrics     = require './onboardingmetrics'
applyMarkdown         = require 'app/util/applyMarkdown'
ThrobberView          = require './throbberview'

module.exports = class OnboardingItemView extends KDView

  ###*
   * Tries to find a target element in DOM.
   * If it's found and target is visible, renders onboarding throbber with tooltip for it.
   * Also, tracks the time user spent to view the onboarding tooltip
   * If path is incorrect and error happens, it saves isError flag and skips exectution.
  ###
  render: ->

    return  if @isError

    { path, name } = @getData()
    { onboardingName, isModal } = @getOptions()

    try
      targetElement = @getElementByPath path
    catch e
      kd.warn "Couldn't create onboarding item. name = #{name}, onboardingName = #{onboardingName}", e
      @isError = yes
      return

    return  unless targetElement.length

    { placementX, placementY, offsetX, offsetY, content, tooltipPlacement, color, targetIsScrollable } = @getData()
    @throbber = new ThrobberView {
      cssClass    : kd.utils.curry color, if isModal then 'modal-throbber' else ''
      delegate    : targetElement
      tooltipText : "<div class='has-markdown'>#{applyMarkdown(content, { sanitize : no }) ? ''}</div>"
      placementX
      placementY
      offsetX
      offsetY
      tooltipPlacement
      targetIsScrollable
    }
    @throbber.on 'TooltipShown', =>
      @startTrackDate = new Date()
    @throbber.on 'TooltipClosed', =>
      @removeThrobber()
      if @startTrackDate
        OnboardingMetrics.trackView onboardingName, name, new Date() - @startTrackDate
      @startTrackDate = null
      @emit 'OnboardingItemCompleted'


  isReady: -> @throbber?


  ###*
   * Searches for a target element by path
   * and returns its jQuery wrapper
   *
   * @param {string} path - path to element
   * @return {jQuery}     - jQuery element
  ###
  getElementByPath: (path) ->

    path = htmlencode.htmlDecode path
    element = $(path).filter((i, item) -> helper.isElementVisible item).first()


  ###*
   * Refreshes throbber according to the target element
  ###
  refresh: ->

    @removeThrobber()
    @render()


  removeThrobber: ->

    return  unless @throbber

    @throbber.destroy()
    @throbber = null


  destroy: ->

    @removeThrobber()
    super


  helper =

    isElementVisible: (element) ->

      return  unless element

      element = $(element)
      return element.is(':visible') and element.css('visibility') isnt 'hidden'
