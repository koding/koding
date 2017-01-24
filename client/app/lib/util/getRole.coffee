isAdmin = require './isAdmin'

module.exports = getRole = -> if isAdmin() then 'admin' else 'member'
