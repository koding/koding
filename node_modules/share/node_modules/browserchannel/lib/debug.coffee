# This enables printing massive amounts of debugging messages to the console.

goog.require 'goog.debug.Logger'

#logger = goog.debug.Logger.getLogger 'goog.net.BrowserChannel'
logger = goog.debug.Logger.getLogger 'goog.net'
logger.setLevel goog.debug.Logger.Level.FINER
logger.addHandler (msg) -> console.log msg.getMessage()
