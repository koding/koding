walk = require 'walk'
fs   = require 'fs'

lookForFile = {}
pathToWalk  = process.argv.splice(2)[0]
walker      = walk.walk pathToWalk, {}

walker.on "file", (root, fileStats, next) ->
  checkUsedFiles = {}
  fs.readFile fileStats.name, () ->
    if fileStats.name.endsWith '.coffee'
      openFile = "#{root}/#{fileStats.name}"
      lookForFile["#{openFile}"] = 1

    next()


walker.on "end", () ->

  for path, value of lookForFile

    checkUsedFiles = {}
    LineNumbers    = {}
    lineNumber     = 1

    require('fs').readFileSync(path).toString().split('\n').forEach (line) ->
      unless line.search(/= require /) == -1
        dependency = "#{line.trim().split("=")[0].trim()}"
        if dependency.startsWith "{"
          dependency = dependency.removeCurly(dependency).trim()
        unless dependency.startsWith "@"
          if dependency.split(",").length > 0
            for dep in dependency.split(",")
              dep = dep.trim()
              checkUsedFiles["#{dep}"] = 2
              LineNumbers["#{dep}"]    = lineNumber
          else
            checkUsedFiles["#{dependency}"] = 2
            LineNumbers["#{dependency}"] = lineNumber
      lineNumber = lineNumber + 1


    require('fs').readFileSync(path).toString().split('\n').forEach (line) ->
      if line.length > 0
        for k, v of checkUsedFiles
          if line.indexOf(k, 0) > -1 and checkUsedFiles[k] > 0
            checkUsedFiles[k] = checkUsedFiles[k] - 1


    for k, v of checkUsedFiles
      if v>0
        linenumber = LineNumbers["#{k}"]
        console.log "There are unused dependency in #{path}:#{linenumber}", k


String::removeCurly = (s) -> @[1...s.length-1]
String::startsWith ?= (s) -> @[...s.length] is s
String::endsWith   ?= (s) -> s is '' or @[-s.length..] is s