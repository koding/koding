kd     = require 'kd'
view   = require './viewhelpers'
whoami = require 'app/util/whoami'

module.exports = class ManagedVMBaseModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.width   ?= 640
    options.cssClass = kd.utils.curry 'managed-vm modal', options.cssClass

    super options, data

    @addSubView @container = new kd.View

    @states  =
      initial: (data) =>
        view.addTo @container, message: text: 'Override this state first.'

  switchTo: (state, data)->

    @container.destroySubViews()

    unless @states[state]?
      console.warn "Requested state #{state} not found, using 'initial'."
      state = 'initial'

    stateFn = @states[state]
    stateFn data


  viewAppended: ->

    view.addTo @container, waiting: ''

    @fetchOtaToken (err, token) =>

      console.warn "Couldn't fetch otatoken:", err  if err

      view._otatoken = if err or not token
      then '# Failed to fetch one time access token.'
      else token

      @switchTo 'initial'


  fetchKites: ->

    {queryKites} = require './helpers'

    queryKites()
      .then (kites) =>
        if kites?.length
        then @switchTo 'listKites', kites
        else @switchTo 'retry', 'No kite instance found'
      .catch (err) =>
        console.warn "Error:", err
        @switchTo 'retry', 'Failed to query kites'


  ###*
   * Fetches one time accesstoken from JAccount
   *
   * @param {Function(err, token)} callback
  ###
  fetchOtaToken: (callback)->

    kd.singletons.mainController.ready =>
      whoami().fetchOtaToken (err, token) =>
        if err then callback err
        else callback null, token
