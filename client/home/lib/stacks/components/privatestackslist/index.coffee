connectCompute = require 'app/providers/connectcompute'

Container = require './container'

module.exports = require './view'

module.exports.Container = connectCompute({
  storage: ['stacks', 'templates', 'machines']
})(Container)
