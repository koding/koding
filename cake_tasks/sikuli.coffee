{spawn, exec} = require 'child_process'

installSikuli =->
  path = "/Applications/Sikuli-IDE.app"
  exec "ls #{path}", (error, stdout, stderr)->
    if error
      sikuliUrl  = "https://launchpad.net/sikuli/sikulix/x1.0-rc3/+download/Sikuli-X-1.0rc3%20%28r905%29-osx-10.6.dmg"
      sikuliFile = "/tmp/sikuli.dmg"

      wget = spawn "wget", [sikuliUrl, "-O#{sikuliFile}"]

      wget.stderr.on 'data', (data)->
        process.stdout.write data.toString()
        process.exit

      wget.stdout.on 'data', (data)->
        process.stdout.write data.toString()

      wget.on 'close', (code)->
        exec "open #{sikuliFile}", (error, stdout, stderr)->
          afterSikuliInstall ->
            console.log "Sikuli is now installed. Run 'cake test'"
    else
      afterSikuliInstall ->
        console.log "Sikuli is already installed at #{path}...exiting."

afterSikuliInstall = (callback)->
  exec "git submodule init; git submodule update", (error, stdout, stderr)->
    exec "mongo koding migrate/insert-testuser.js", (error, stdout, stderr)->
      callback()

runSikuli =->
  url =  "http://localhost:3020"

  console.log "Opening '#{url}' in Google Chrome to run the tests."
  console.log "Running tests. Be sure you're logged out of Koding or this test will fail.\n"

  # So people can see the above log messages.
  setTimeout ->
    exec 'open -a "Google Chrome" "http://localhost:3020"', ->
      exec '/Applications/Sikuli-IDE.app/sikuli-ide.sh -r `pwd`/tests/mac/signup_login.sikuli --stderr', (error, stdout, stderr)->
        if stderr
          console.log stderr, "\n"
          console.log "Tests failed. It's possible Sikuli image matching failed. If you think that's the case, please try again."
          exec 'say "TESTS FAILED"', ->
  , 3000

exports.installSikuli = installSikuli
exports.runSikuli = runSikuli
