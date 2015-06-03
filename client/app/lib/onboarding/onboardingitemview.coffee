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
  render: (skipErrors) ->

    { path, name } = @getData()
    { groupName, isModal } = @getOptions()

    try
      @targetElement = @getViewByPath path
      @targetElement.on 'KDObjectWillBeDestroyed', @bound 'handleTargetDestroyed'

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
        @show()
      else unless skipErrors
        console.warn 'Target element should be an instance of KDView and should be visible', { name, groupName }
    catch e
      console.warn "Couldn't create onboarding item", { name, groupName, e }  unless skipErrors


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
   * Refreshes throbber according to the target element
   * visibility and position.
   * If target element is absent, it tries to find it in DOM
   * and if it exists, re-renders throbber for it
  ###
  refresh: ->

    if @targetElement?.isInDom()
      domElement = @targetElement.getDomElement()
      visible = domElement.is(':visible') and domElement.css('visibility') isnt 'hidden'
      if visible
        @show()
        @throbber.setPosition()
      else @hide()
    else
      @throbber?.destroy()
      @render yes


  show: -> @throbber?.show()


  hide: -> @throbber?.hide()


  handleTargetDestroyed: ->

    @targetElement = null
    @throbber?.destroy()


  destroy: ->

    @handleTargetDestroyed()
    super