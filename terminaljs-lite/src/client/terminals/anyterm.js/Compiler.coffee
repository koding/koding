{readModule} = require "../../common/util"
class Compiler
  @compile:()->
    js =  readModule require.resolve "anyterm.js/DiffScript"
    js += readModule require.resolve "./Client"
    
module.exports = Compiler
