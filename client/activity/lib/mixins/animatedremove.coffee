kd = require 'kd'

ANIMATION_TIME = 347

###*
 * Overrides `hide` method of attached view to inject animation related css
 * classes.
###
hide = ->

  @setClass 'half no-anim'


###*
 * Overrides `show` method of attached view to inject animation related css
 * functionality. It then calls the constructor to continue.
###
show = ->

  @unsetClass 'half no-anim out'

  # manual super call.
  kd.View::show.call this


###*
 * This is where the animation happens. It first animates the margin, and then
 * when it is finished it hides the element and emits an event to let know the
 * animation is finished.
 *
 * @emits RemoveAnimationFinished
####
remove = ->

  @unsetClass 'half no-anim'
  @setClass 'out'

  kd.utils.wait ANIMATION_TIME, =>
    height = @getHeight()
    element = @getElement()
    margin = calculateMargin element
    @setCss 'margin-top', "-#{height + margin}px"

    kd.utils.wait ANIMATION_TIME, =>
      @setClass 'hidden'
      @emit 'RemoveAnimationFinished'
      @_removed = yes


###*
 * A hook to pass callbacks to run when the animation is finished.
 *
 * @param {function} callback
###
whenRemovingFinished = (callback) ->

  if @_removed
  then callback()
  else @once 'RemoveAnimationFinished', callback


###*
 * It returns the total amount of margins of given dom element. This is being
 * used to calculate the margin-top property when animating the view with
 * reducing the margin-top property.
 *
 * @param {DOMElement} element
 * @return {number} total - total amount of margins from top and bottom.
###
calculateMargin = (element) ->

  style = global.getComputedStyle element
  total = ['margin-top', 'margin-bottom'].reduce (total, property) ->
    calculated = parseInt (style.getPropertyValue property), 10
    calculated = 0  if isNaN calculated
    return total + calculated
  , 0

  return total


module.exports = {
  hide
  show
  remove
  whenRemovingFinished
}
