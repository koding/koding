getGroup = require 'app/util/getGroup'

module.exports = teamHasStack = -> !!getGroup().stackTemplates?.length
