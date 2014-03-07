class SuggestedTokenView extends TokenView
  constructor: (options = {}, data) ->
    options.cssClass  = KD.utils.curry "suggested", options.cssClass
    options.pistachio = ""
    super options, data

  getPrefix: ->
    return  @getOptions().prefix

  getKey: ->
    return  "$suggest"

  getIdentity: ->
    {$suggest} = @getData()
    return  "#{@getKey()}:#{$suggest}"

  pistachio: ->
    {prefix}   = @getOptions()
    {$suggest} = @getData()
    "#{prefix}#{Encoder.XSSEncode $suggest}"
