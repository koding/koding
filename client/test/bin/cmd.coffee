#!/usr/bin/env coffee

argv = require 'yargs'
  .usage 'usage: $0 <command> [options]'

  .help 'help'
  .alias 'help', 'h'
  .describe 'help', 'show this message'

  .describe 'url', 'specify a url that koding webserver is running on'
  .string 'url'
  .default 'url', 'http://localhost:8090'

  .config 'nightwatch'
  .default 'nightwatch', __dirname + '/nightwatch-blueprint.json'
  .describe 'nightwatch', 'specify a nightwatch config blueprint file. actual config file will be written to client/.nightwatch.json'

  .describe 'start-selenium', 'if enabled starts a selenium server process'
  .boolean 'start-selenium'
  .default 'start-selenium', no

  .argv


os = require 'os'
fs = require 'fs'
path = require 'path'

cliArgs = ['help', '$0', 'h', 'url', '_', 'nightwatch', 'start-selenium']

nwConfig = {}

for k, v of argv
  if not ~cliArgs.indexOf k
    nwConfig[k] = v

platform = os.platform()

if platform is 'linux'
  platform = 'linux64'
else if platform is 'darwin'
  platform = 'mac32'

nwConfig.selenium.start_process = argv.startSelenium
nwConfig.selenium.server_path = path.resolve __dirname, nwConfig.selenium.server_path

nwConfig.selenium.log_path = path.resolve __dirname, nwConfig.selenium.log_path
nwConfig.test_settings.default.screenshots.path =
  path.resolve __dirname, nwConfig.test_settings.default.screenshots.path

nwConfig.output_folder = path.resolve __dirname, nwConfig.output_folder

nwConfigFile = path.resolve __dirname, '../../.nightwatch.json'
fs.writeFileSync nwConfigFile, JSON.stringify(nwConfig, null, 2)
console.log "written #{nwConfigFile}"

configFile = path.resolve __dirname, '../../.config.json'
config = require configFile
config.test =
  url: argv.url
fs.writeFileSync configFile, JSON.stringify config
console.log "written #{configFile}"
