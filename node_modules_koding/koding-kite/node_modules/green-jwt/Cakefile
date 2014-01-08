fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'

# ANSI Terminal Colors
bold = '\x33[0;1m'
green = '\x33[0;32m'
reset = '\x33[0m'
red = '\x33[0;31m'

log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

print = (data) -> console.log data.toString().trim()

handleError = (err) ->
  if err
    #console.log "\n\x33[1;36m=>\x33[1;37m Remember that you need: coffee-script@0.9.4 and mocha@0.5.2\x33[0;37m\n"
    log "Remember that you need: coffee-script@0.9.4 and mocha@0.5.2", red
    console.log err.stack

task 'install', 'Executes an install of the required packages.', ->
  exec 'npm install'

task 'build', 'Compile Coffeescript source to Javascript', ->
  exec 'mkdir -p lib && coffee -c -o lib src', handleError
  exec 'find lib -name "*.js" -print0 | xargs -0 jslint --stupid'

task 'clean', 'Remove generated Javascripts', ->
  exec 'rm -fr lib', handleError

task 'test', 'Test the app', (options) ->
  console.log "\n\x1B[00;33m=>\x1B[00;32m Running tests..\x1B[00;33m\n"
  mocha = spawn 'mocha', '-c -b --compilers coffee:coffee-script -R spec'.split(' ')
  mocha.stdout.on 'data', (data) -> print data.toString()
  mocha.stderr.on 'data', (data) -> log data.toString(), red

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> log data.toString(), red
    docco.on 'exit', (status) -> callback?() if status is 0

task 'dev', 'Continuous compilation', ->
  coffee = spawn 'coffee', '-wc --bare -o lib src'.split(' ')
  coffee.stdout.on 'data', print
  coffee.stderr.on 'data', print
