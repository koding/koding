Promise = require 'bluebird'
del     = Promise.promisify require 'del'

{ BUILD_PATH } = require './helper.constants'

module.exports = -> del [BUILD_PATH], { force: yes }
