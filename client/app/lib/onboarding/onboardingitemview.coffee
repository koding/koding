htmlencode            = require 'htmlencode'
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
  ###
  render: ->

    { path, name } = @getData()
    { groupName, isModal } = @getOptions()

    try
      @targetElement = @getViewByPath path

      if @targetElement and not @targetElement.hasClass 'hidden'
        { placementX, placementY, offsetX, offsetY, content, tooltipPlacement, color } = @getData()
        @throbber = new ThrobberView {
          cssClass    : kd.utils.curry color, if isModal then 'modal-throbber' else ''
          delegate    : @targetElement
          tooltipText : "<div class='has-markdown'>#{applyMarkdown(content) ? ''}</div>"
          placementX
          placementY
          offsetX
          offsetY
          tooltipPlacement
        }
        @throbber.on 'TooltipReady', =>
          @startTrackDate = new Date()
          @isViewed       = yes
        @throbber.tooltip.on 'ReceivedClickElsewhere', =>
          return  unless @startTrackDate
          OnboardingMetrics.trackView groupName, name, new Date() - @startTrackDate
          @startTrackDate = null
        @throbber.on 'click', =>
          if @isViewed
            @throbber.destroy()
            @emit 'OnboardingItemCompleted'
      else
        console.warn 'Target element should be an instance of KDView and should be visible', { name, groupName }
    catch e
      console.warn "Couldn't create onboarding item", { name, groupName, e }


  ###*
   * Searches for a target element by path
   * If the element is in DOM, tries to find a kd instance for it
   *
   * @param {string} path - path to element
   * @return {KDView}     - kd view for the path if it exists
  ###
  getViewByPath: (path) ->

    path = htmlencode.htmlDecode path
    element = document.querySelector path

    return  unless element

    for key, kdinstance of kd.instances
      if kdinstance.getElement?() is element
        return kdinstance


  ###*
   * Refreshes throbber visibility according
   * to the target element visibility
  ###
  refreshVisiblity: ->

    return  unless @throbber

    domElement = @targetElement.getDomElement()
    visible = domElement.is(':visible') and domElement.css('visibility') isnt 'hidden'
    visible = @targetElement.isInDom()  if visible

    if visible
      @throbber.show()
    else
      @throbber.hide()


  destroy: ->

    @throbber?.destroy()
    super