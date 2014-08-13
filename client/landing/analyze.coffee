#!/usr/bin/env coffee

{ exec }   = require 'child_process'
colors     = require 'colors'
fs         = require 'fs'

command    = """grep -e "^class \s*" * -R | grep -v Framework"""

files      = {}
fileNames  = []
classes    = {}
classNames = []

relations  = []
conflicts  = {}
fileIssues = {}

projects   = {}

graph = """
digraph G {
  graph [fontsize=10 compound=false ranksep=2];
  layout=dot;
  rankdir="LR";
  overlap = false;
  node[shape=record, height="0.4", width="0.4"];
  edge[dir=none];

"""

colorDisabled = "--plain" in process.argv

log = (message, color)->

  if not colorDisabled and color?
    message = "#{message}"[color]

  console.log message


log "Parsing source files...", 'yellow'

exec command, (err, res)->

  return console.error err  if err

  for line in res.split '\n' when line
    [file, rest] = line.split ':'
    [_c, klass, _e, eklass] = rest.split ' '
    [project] = file.split '/'

    projects[project] ?= []

    files[file] ?= []
    files[file].push klass
    fileNames.push file

    if klass in classNames
      unless conflicts[klass]?
        conflicts[klass] = [ classes[klass].file ]
        hasConflicts = yes
      conflicts[klass].push file

    classNames.push klass

    classes[klass] = { class: klass, file }

    projects[project].push classes[klass]

    if _e and eklass
      classes[klass].extends = eklass
      relations.push { class: klass, extends: eklass }
      graph += """  "#{klass}" -> "#{eklass}";\n"""

  i = 0
  for _p, project of projects
    graph += """  subgraph "cluster_#{i}" { node [style=filled]; color=blue; label="#{_p}"; """
    for _klass in project
      graph += """ "#{_klass.class}"; """
    graph += "}\n"
    i++

  graph += "}"

  for _f, file of files
    if file.length > 1
      fileIssues[_f] = file
      hasFileIssues = yes

  log "Parsing completed. #{classNames.length} classes found.", 'green'
  log "Writing graph data to ../docs/koding-dep.graph\n"

  fs.writeFileSync "../docs/koding-dep.graph", graph

  if hasConflicts?

    log "Following classes are defined more than once:\n", 'red'
    log conflicts
    log ""

  if hasFileIssues?

    log "Following files have more than one class in it:\n", 'yellow'
    log fileIssues
    log ""


  log "Checking for usages... (this may take time) ... safe to stop with ctrl+c", 'yellow'
  log "Following classes from pointed files may not be used in the code:", 'red'
  log "Uses 'ack' app, you can install it via '$ brew install ack'", 'cyan'

  lastProject = null

  findUsage = (i)->

    klass = classNames[i]

    # Ignore AppController classes...
    unless colorDisabled
      process.stdout.write "\r\r#{i} - working on #{klass}\r"

    if /AppController.coffee$/.test classes[klass].file
      if i < classNames.length - 1 then findUsage i+1
      return

    exec """ack -hc "#{klass}" """, (err, res)->
      if (parseInt res) is 1
        klass = classes[klass]
        project = (klass.file.split '/')[0]
        if project isnt lastProject
          lastProject = project
          log "\n\nFrom #{lastProject} project ....................\n", 'cyan'

        if colorDisabled
          log "#{klass.class} from #{klass.file}"
        else
          c = "#{klass.class}".yellow; f = "#{klass.file}".blue;
          log "#{c} from #{f}"

      findUsage i+1  if i < classNames.length - 1

  findUsage 0
