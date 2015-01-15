class NFinderRenameInput extends KDHitEnterInputView
  constructor: (options = {}, data) ->
    super options, data
    @once "viewAppended", @bound "selectAll"

  click    : -> no
  dblClick : -> no

module.exports = NFinderRenameInput
