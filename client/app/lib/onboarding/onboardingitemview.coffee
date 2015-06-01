htmlencode            = require 'htmlencode'
kd                    = require 'kd'
KDView                = kd.View
OnboardingMetrics     = require './onboardingmetrics'
applyMarkdown         = require 'app/util/applyMarkdown'
ThrobberView          = require './throbberview'

module.exports = class OnboardingItemView extends KDView

  ###*
   * Tries to find a target element in DOM
   * If it's found, renders onboarding tooltip for it
   * Otherwise, emits an event to let know that onboarding item can't be shown
   *
   * @emits OnboardingFailed
  ###
  render: ->

    { path, name } = @getData()
    { groupName  } = @getOptions()

    try
      @targetElement = @getViewByPath path

      if @targetElement and not @targetElement.hasClass 'hidden'
        { placementX, placementY, offsetX, offsetY, content, tooltipPlacement, color } = @getData()
        @throbber = new ThrobberView {
          cssClass    : color
          delegate    : @targetElement
          tooltipText : "<div class='has-markdown'>#{applyMarkdown(content) ? ''}</div>"
          placementX
          placementY
          offsetX
          offsetY
          tooltipPlacement
        }
        @throbber.tooltip.on 'viewAppended', ->
          OnboardingMetrics.collect groupName, name
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


  destroy: ->

    @throbber?.destroy()
    super