kd = require 'kd'
KDObject = kd.Object
OnboardingConstants = require './onboardingconstants'

###*
 * A class that executes a specific method for a list of items
 * until either method is successfully executed for all items or
 * max time for the task is passed.
 * It's used to render and refresh onboarding items when their
 * target elements are rendered with a delay
###
module.exports = class OnboardingTask extends KDObject

  constructor: (items, itemMethod) ->

    @maxTime      = OnboardingConstants.TASK_MAX_TIME
    @timeInterval = OnboardingConstants.TASK_TIME_INTERVAL
    @startTime  = new Date()

    kd.utils.defer => @processItems items, itemMethod
    

  ###*
   * Executes itemMethod for each item in items.
   * For all items which return error it repeats processing
   * with delay of @timeInterval.
   * If the task works more that @maxTime, it stops and logs
   * all item errors in console
   *
   * @param {Array} items       - a list of items
   * @param {string} itemMethod - name of method which should be executed for each item
  ###
  processItems: (items, itemMethod) ->

    failedItems = []
    errors      = []

    for item in items
      result = item[itemMethod]?()
      if result instanceof Error
        failedItems.push item
        errors.push result

    if errors.length > 0
      if new Date() - @startTime >= @maxTime
        for error in errors
          kd.warn "Onbarding: #{error.message}"
      else
        kd.utils.wait @timeInterval, @lazyBound 'processItems', failedItems, itemMethod
