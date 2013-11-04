
# Fetch version info from VERSION file
fs          = require 'fs'
nodePath    = require 'path'
versionFile = nodePath.join(__dirname, 'VERSION')
if fs.existsSync versionFile
  version = (fs.readFileSync versionFile, 'utf-8').trim()

FRAMEWORK_VERSION = version ? "0.0.1"
KODING_VERSION    = version ? "0.0.1"

projects      =

  KDFramework :
    files     : "client/Framework/includes.coffee"
    style     : "website/css/kd.#{FRAMEWORK_VERSION}.css"
    script    : "website/js/kd.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Framework/"

  KDBackend   :
    files     : "client/Bongo/includes.coffee"
    script    : "website/js/bongo.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Bongo/"

  KDMainApp   :
    files     : "client/includes.coffee"
    style     : "website/css/kdapp.#{KODING_VERSION}.css"
    script    : "website/js/kdapp.#{KODING_VERSION}.js"

  TestApp     :
    files     : "client/testapp/includes.coffee"
    style     : "website/css/testapp.css"
    script    : "website/js/testapp.js"

  HomeIntro   :
    files     : "client/introapp/includes.coffee"
    style     : "website/css/introapp.#{KODING_VERSION}.css"
    script    : "website/js/introapp.#{KODING_VERSION}.js"

bundles       =

  Koding      :
    projects  : ['KDBackend', 'KDMainApp']
    style     : "website/css/koding.#{KODING_VERSION}.css"
    script    : "website/js/koding.#{KODING_VERSION}.js"


module.exports  = {projects, bundles}