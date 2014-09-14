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

    classes[klass] = { name: klass, file }

    projects[project].push classes[klass]

    if _e and eklass
      classes[klass].extends = eklass
      relations.push { name: klass, extends: eklass }
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


  if hasFileIssues?

    log "Following files have more than one class in it:\n", 'red'
    for _file, _classes of fileIssues
      log """
        #{_file} includes #{_classes.length} classes:
          \t#{_classes.join ', '}

      """, 'yellow'


  log "Checking for usages... (this may take time) ... safe to stop with ctrl+c", 'yellow'
  log "Following classes from pointed files may not be used in the code:", 'red'
  unless colorDisabled
    log "Uses 'ack' app, you can install it via '$ brew install ack'", 'cyan'

  koding = require '../projects'

  getProject = (path)->

    for name, project of koding.projects
      if ///^#{project.path}///.test "client/#{path}"
        return project.sourceMapRoot

  lastProject     = null
  projectIncludes = []
  notIncluded     = []
  CoffeeScript    = require 'coffee-script'

  findUsage = (i)->

    iterate = ->
      if i < classNames.length - 1
        findUsage i+1
      else
        log "Individual analyze completed.\n", 'green'
        log "Warning: following classes is not even included in any project:", 'yellow'
        for _klass in notIncluded
          log " - class #{_klass.name} from #{_klass.file}"

    klass   = classes[classNames[i]]
    project = getProject klass.file

    unless project
      log """
        Path couldn't recognized: #{klass.file}
        (it is possible that there is no project definition for this file)
      """, 'red'
      return iterate()

    fpath   = klass.file.replace ///^#{project}///, ''

    if project isnt lastProject
      lastProject = project
      log "\nChecking #{lastProject} project ....................", 'cyan'
      try
        projectIncludes = CoffeeScript.eval fs.readFileSync "#{project}includes.coffee", "utf-8"
      catch e
        log "Project #{project} does not have includes.coffee!!!", 'red'
        projectIncludes = []

    # Ignore AppController classes...
    unless colorDisabled
      process.stdout.write "\r\r#{i} - working on #{klass.name}\r"

    if /AppController.coffee$/.test klass.file
      return iterate()

    exec """ack -hc "#{klass.name}" """, (err, res)->

      if fpath in projectIncludes
        if (parseInt res) is 1
          if colorDisabled
            log "#{klass.name} from #{klass.file}"
          else
            c = "#{klass.name}".yellow; f = "#{klass.file}".blue;
            log "#{c} from #{f}"
      else
        notIncluded.push klass

      iterate()

  findUsage 0
