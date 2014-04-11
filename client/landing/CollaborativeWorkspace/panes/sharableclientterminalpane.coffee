class SharableClientTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    sessionOptions   = options.sessionKey
    options.vmName   = sessionOptions.vmName
    options.vmRegion = sessionOptions.vmRegion
    options.joinUser = sessionOptions.host
    options.session  = sessionOptions.key
    options.delay    = 0

    super options, data

  getMode: -> 'shared'

  fetchVm: (callback)->
    {vmName, vmRegion} = @getOptions()

    callback null,
      hostnameAlias : vmName
      region        : vmRegion
