kd          = require 'kd'
actionTypes = require './actiontypes'

###*
 * Action to set a query of emoji selectbox.
 * If query is empty or not defined, unsetSelectBoxQuery()
 * is called to unset current query.
 * Once the query is set, selected index and tab index of
 * emoji selectbox should be reset
 *
 * @param {string} stateId
 * @param {string} query
###
setSelectBoxQuery = (stateId, query) ->

  if query
    { SET_EMOJI_SELECTBOX_QUERY } = actionTypes
    dispatch SET_EMOJI_SELECTBOX_QUERY, { stateId, query }
    resetSelectBoxSelectedIndex stateId
    resetSelectBoxTabIndex stateId
  else
    unsetSelectBoxQuery stateId


###*
 * Action to unset current query of emoji selectbox
 *
 * @param {string} stateId
###
unsetSelectBoxQuery = (stateId) ->

  { UNSET_EMOJI_SELECTBOX_QUERY } = actionTypes
  dispatch UNSET_EMOJI_SELECTBOX_QUERY, { stateId }

  resetSelectBoxSelectedIndex { stateId }


###*
 * Action to set selected index of emoji selectbox
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectBoxSelectedIndex = (stateId, index) ->

  { SET_EMOJI_SELECTBOX_SELECTED_INDEX } = actionTypes
  dispatch SET_EMOJI_SELECTBOX_SELECTED_INDEX, { stateId, index }


###*
 * Action to reset selected index of emoji selectbox
 * to initial value
 *
 * @param {string} stateId
###
resetSelectBoxSelectedIndex = (stateId) ->

  { RESET_EMOJI_SELECTBOX_SELECTED_INDEX } = actionTypes
  dispatch RESET_EMOJI_SELECTBOX_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility flag of emoji selectbox
 * After visibility is changed, we need to reset
 * selectbox query and tab index to initial values
 *
 * @param {string} stateId
 * @param {bool} visible
###
setSelectBoxVisibility = (stateId, visible) ->

  { SET_EMOJI_SELECTBOX_VISIBILITY } = actionTypes
  dispatch SET_EMOJI_SELECTBOX_VISIBILITY, { stateId, visible }

  unsetSelectBoxQuery stateId
  resetSelectBoxTabIndex stateId


###*
 * Action to set current tab index
 *
 * @param {string} stateId
 * @param {number} tabIndex
###
setSelectBoxTabIndex = (stateId, tabIndex) ->

  { SET_EMOJI_SELECTBOX_TAB_INDEX } = actionTypes

  dispatch SET_EMOJI_SELECTBOX_TAB_INDEX, { stateId, tabIndex }


###*
 * Action to reset current tab index to initial value 0
 *
 * @param {string} stateId
###
resetSelectBoxTabIndex = (stateId) -> setSelectBoxTabIndex stateId, 0


getAppStorage = -> kd.singletons.appStorageController.storage 'Emoji', '1.0.0'


###*
 * Action to load emoji usage counts from app storage
 * and update EmojiUsageCountsStore with storage data
###
loadUsageCounts = ->

  { SET_EMOJI_USAGE_COUNT } = actionTypes

  storage = getAppStorage()
  storage.fetchStorage ->
    counts = storage.getValue('usageCounts') ? {}
    kd.singletons.reactor.batch ->
      for emoji, count of counts
        dispatch SET_EMOJI_USAGE_COUNT, { emoji, count }


###*
 * Action to increment emoji usage count
 *
 * @param {string} emoji
###
incrementUsageCount = (emoji) ->

  { INCREMENT_EMOJI_USAGE_COUNT } = actionTypes

  dispatch INCREMENT_EMOJI_USAGE_COUNT, { emoji }

  usageCounts = kd.singletons.reactor.evaluateToJS [ 'EmojiUsageCountsStore' ]
  getAppStorage().setValue 'usageCounts', usageCounts


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setSelectBoxQuery
  unsetSelectBoxQuery
  setSelectBoxSelectedIndex
  resetSelectBoxSelectedIndex
  setSelectBoxVisibility
  setSelectBoxTabIndex

  loadUsageCounts
  incrementUsageCount
}
