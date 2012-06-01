{readModule}    = require "./common/util"
fs              = require "fs"

class TerminalClientCompiler  
  @compileClient:()->
    code     = fs.readFileSync __dirname+"/../Errno", 'utf-8'
    code    += fs.readFileSync __dirname+"/terminals/anyterm.js/Errno", 'utf-8'
    code    += fs.readFileSync __dirname+"/../Errno", 'utf-8'
    
    # Compiler = require "./terminals/anyterm.js/Compiler"
    # code    += Compiler.compile()
    return code


module.exports = TerminalClientCompiler
