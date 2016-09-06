JView = require 'app/jview'


module.exports = class ActivityItemMenuItem extends JView

  pistachio: ->

    { title } = @getData()
    """
    #{title}
    """
