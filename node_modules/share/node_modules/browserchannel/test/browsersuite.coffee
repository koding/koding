# This is the main entrypoint for the browser nodeunit tests.

nodeunit.run
  'browser socket': require './bcsocket'
  #'Bare goog.net.browserchannel': require './browserchannel'

