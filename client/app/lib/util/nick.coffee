whoami = require './whoami'

module.exports = -> whoami()?.profile?.nickname
