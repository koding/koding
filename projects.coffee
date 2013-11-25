
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
    files     : "client/Main/includes.coffee"
    style     : "website/css/kdapp.#{KODING_VERSION}.css"
    script    : "website/js/kdapp.#{KODING_VERSION}.js"
    sourceMapRoot : "Main/"

  # TestApp     :
  #   files     : "client/Testapp/includes.coffee"
  #   style     : "website/css/testapp.css"
  #   script    : "website/js/testapp.js"

  HomeIntro   :
    files     : "client/Intro/includes.coffee"
    style     : "website/css/introapp.#{KODING_VERSION}.css"
    script    : "website/js/introapp.#{KODING_VERSION}.js"
    sourceMapRoot : "introapp/"

  Landing     :
    files     : "client/landing/includes.coffee"
    style     : "website/css/landingapp.#{KODING_VERSION}.css"
    script    : "website/js/landingapp.#{KODING_VERSION}.js"
    sourceMapRoot : "landing/"

  Activity        :
    files         : "client/Social/Activity/includes.coffee"
    style         : "website/css/app.activity.#{KODING_VERSION}.css"
    script        : "website/js/app.activity.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Activity/"

  Members         :
    files         : "client/Social/Members/includes.coffee"
    style         : "website/css/app.members.#{KODING_VERSION}.css"
    script        : "website/js/app.members.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Members/"

  Topics          :
    files         : "client/Social/Topics/includes.coffee"
    style         : "website/css/app.topics.#{KODING_VERSION}.css"
    script        : "website/js/app.topics.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Topics/"

  Feeder          :
    files         : "client/Social/Feeder/includes.coffee"
    style         : "website/css/app.feeder.#{KODING_VERSION}.css"
    script        : "website/js/app.feeder.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Feeder/"

  # Groups          :
  #   files         : "client/Groups/includes.coffee"
  #   style         : "website/css/app.groups.#{KODING_VERSION}.css"
  #   script        : "website/js/app.groups.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Groups/"

  Account         :
    files         : "client/Account/includes.coffee"
    style         : "website/css/app.account.#{KODING_VERSION}.css"
    script        : "website/js/app.account.#{KODING_VERSION}.js"
    sourceMapRoot : "Account/"

  Login           :
    files         : "client/Login/includes.coffee"
    style         : "website/css/app.Login.#{KODING_VERSION}.css"
    script        : "website/js/app.Login.#{KODING_VERSION}.js"
    sourceMapRoot : "Login/"

  Apps            :
    files         : "client/Social/Apps/includes.coffee"
    style         : "website/css/app.apps.#{KODING_VERSION}.css"
    script        : "website/js/app.apps.#{KODING_VERSION}.js"
    sourceMapRoot : "Social/Apps/"

  Terminal        :
    files         : "client/Terminal/includes.coffee"
    style         : "website/css/app.terminal.#{KODING_VERSION}.css"
    script        : "website/js/app.terminal.#{KODING_VERSION}.js"
    sourceMapRoot : "Terminal/"

  Ace             :
    files         : "client/Ace/includes.coffee"
    style         : "website/css/app.ace.#{KODING_VERSION}.css"
    script        : "website/js/app.ace.#{KODING_VERSION}.js"
    sourceMapRoot : "Ace/"

  Finder          :
    files         : "client/Finder/includes.coffee"
    style         : "website/css/app.finder.#{KODING_VERSION}.css"
    script        : "website/js/app.finder.#{KODING_VERSION}.js"
    sourceMapRoot : "Finder/"

  PostOperations  :
    files         : "client/PostOperations/includes.coffee"
    script        : "website/js/client.post.#{KODING_VERSION}.js"

bundles           =

  Social          :
    projects      : ['Activity', 'Members', 'Topics']
    style         : "website/css/social.#{KODING_VERSION}.css"
    script        : "website/js/social.#{KODING_VERSION}.js"

  Koding          :
    projects      : ['KDBackend', 'KDMainApp', 'Finder', 'Login', 'PostOperations']
    style         : "website/css/koding.#{KODING_VERSION}.css"
    script        : "website/js/koding.#{KODING_VERSION}.js"


module.exports  = {projects, bundles}
