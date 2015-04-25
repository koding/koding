CustomViewItem = require './views/customviews/customviewitem'


module.exports = class OnboardingChildItem extends CustomViewItem

  delete: -> @emit "ViewDeleted", @getData()



