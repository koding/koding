Helpers = Timer: (callback, delay) ->

  timerId = undefined
  start = undefined
  remaining = delay

  @pause = ->

    clearTimeout timerId
    remaining -= new Date - start
    return


  @resume = ->

    start = new Date
    clearTimeout timerId
    timerId = setTimeout(callback, remaining)
    return


  @clear = ->
    
    clearTimeout timerId
    return


  @resume()

module.exports = Helpers
