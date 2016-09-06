kd = require 'kd'
KDAutoCompleteFetchingItem = kd.AutoCompleteFetchingItem
module.exports = class FetchingActivityAutoCompleteUserItemView extends KDAutoCompleteFetchingItem

  constructor: (options = {}, data) ->
    
    options.type = 'dropdown-member'
    
    super options, data
