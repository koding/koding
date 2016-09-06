kd = require 'kd'
KDAutoCompleteController = kd.AutoCompleteController

module.exports = class ParticipantSearchController extends KDAutoCompleteController

  {log} = kd
  ### @constant {number} ###
  SHOW_LOADER_TIMEOUT = 1000

  constructor: (options = {}, data) ->

    super options, data

    @extendEvents()


  ###*
   * Extends the events of KDAutoCompleteController.
   *
   * @emits ItemSelected - when a new participant added.
   * @emits ItemDeselected - when a new participant removed.
  ###
  extendEvents: ->

    initialCount = 0

    @on 'ItemListChanged', (count) =>

      return  if count is initialCount

      if count > initialCount
      then @emit 'ItemSelected'
      else @emit 'ItemDeselected'


  ###*
   * Removes a selected participant from the selected list.
   *
   * @param {JAccount} participant
  ###
  removeSelectedParticipant: (participant) ->

    return  unless participant in @getSelectedItemData()

    @removeSelectedItemData participant
    @selectedItemCounter--


  ###*
   * Full override for delaying `showFetching` method.
  ###
  updateDropdownContents:->

    inputView = @getView()
    value     = inputView.getValue().trim()

    return @hideDropdown() if value is ''

    return if @active and value is @dropdownPrefix

    @dropdownPrefix = value

    {fetchInterval} = @getOptions()

    # delay the execution of show loading method.
    # if the fetching happens before timeout constant
    # we will simply kill the waited version of the function.
    # so that the loader will not be shown, and it will result in
    # a better UX. ~Umut
    delayed = kd.utils.wait SHOW_LOADER_TIMEOUT, => @showFetching()

    @fetch kd.utils.debounce fetchInterval, (data) =>

      kd.utils.killWait delayed

      if data.length > 0
        @refreshDropDown data
        @showDropdown()
      else
        @showNoDataFound()
