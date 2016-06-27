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
   * If it's found, renders onboarding throbber with tooltip for it.
   * Also, tracks the time user spent to view the onboarding tooltip
   *
   * @return {bool|Error} - yes if target element is found, otherwise - Error object
  ###
  render: ->

    { path, name } = @getData()
    { onboardingName, isModal } = @getOptions()

    try
      @targetElement = @getElementByPath path

      if @targetElement.is ':visible'
        { placementX, placementY, offsetX, offsetY, content, tooltipPlacement, color, targetIsScrollable } = @getData()
        @throbber = new ThrobberView {
          cssClass    : kd.utils.curry color, if isModal then 'modal-throbber' else ''
          delegate    : @targetElement
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
          @throbber.destroy()
          if @startTrackDate
            OnboardingMetrics.trackView onboardingName, name, new Date() - @startTrackDate
          @startTrackDate = null
          @emit 'OnboardingItemCompleted'
        @show()
      else
        return new Error "Target doesn't exist in DOM or invisible. name = #{name}, onboardingName = #{onboardingName}"
    catch e
      return new Error "Couldn't create onboarding item. name = #{name}, onboardingName = #{onboardingName}"

    return yes


  ###*
   * Searches for a target element by path
   * and returns its jQuery wrapper
   *
   * @param {string} path - path to element
   * @return {jQuery}     - jQuery element
  ###
  getElementByPath: (path) ->

    path = htmlencode.htmlDecode path
    element = $(path).first()


  ###*
   * Refreshes throbber according to the target element
   * visibility and position.
   * If target element is absent, it tries to find it in DOM
   * and if it exists, re-renders throbber for it
  ###
  refresh: ->

    if @targetElement?.closest('body').length
      visible = @targetElement.is(':visible') and @targetElement.css('visibility') isnt 'hidden'
      if visible
        @show()
        @throbber.setPosition()
      else @hide()
      return yes
    else
      @throbber?.destroy()
      return @render()


  show: -> @throbber?.show()


  hide: -> @throbber?.hide()


  handleTargetDestroyed: ->

    @targetElement = null
    @throbber?.destroy()


  destroy: ->

    @handleTargetDestroyed()
    super
