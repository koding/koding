# Koding (the repository)

[![wercker status](https://app.wercker.com/status/8da42fd35762f3883b96b6d85b3f0c46/m "wercker status")](https://app.wercker.com/project/bykey/8da42fd35762f3883b96b6d85b3f0c46)

Welcome! This is the main Koding repository. Below you can find some
information about the folder structure.

* client:  contains all our client based code. Like our KDFramework, css
           assets, our Koding.com mainpage, apps and so on

* config:  contains all our configurations files. All our apps in the codebase
           is reading from this folder to set certain things, like mongdob credentials,
           ports to be bind, number of instances to be run and so on.

* docs:    contains docs about some of our core technologies. Once created,
           they never did get an update for a long time. So don't except
           anything new there (it's needs love)

* go:      contains code that was written in Go language. It contains lot's of our
           core backend technologies. If you write something in Go it goes here.

* migrate: contains migration scripts. These scripts are usually used whenever
           we introduce something new and mongdob needs a major update or if change
           something very deeply.

* node_modules: contains all standard node modules use by our node.js apps and
                symlinks from the node_modules_koding folder. This is populated via the
                package.json file.

* node_modules_koding: contains node modules that were written by Koding developers.
                       If you execute "npm install" a symlink for every folders
                       is created to node_modules folder.

* scripts: contains several handy scripts for certains tasks. please refer to
           scripts/Readme.md for more information

* server:  contains our webserver written in express.js.

* team:    a folder for our remote working developers. You can find the working
           hours of every remote working developers here.

* tests:   PLEASE FILL HERE

* vagrant: PLEASE FILL HERE

* website: assets used by the webserver for our koding.com homepage

* workers: contains all our backend based code. Like authWorker, socialWorker
           and so on. All these workers also carry the associated bongo models.

# Deployment

Deployment process is carried out by script `deploy`. It accepts following options:

* config      : prod, feature or sandbox (default: feature)
* githubuser  : Used for determining base repository of deployment  (default: koding)
* gitremote   : Remote name in local clone for the base repository (default: origin)
* version     : Version number (default: automatically increments latest tag)
* boxes       : Number of instance to launch (default: 1)
* boxtype     : EC2 instance type (default: t2.medium)
* versiontype : major, premajor, minor, preminor, patch, prepatch, or prerelease (default: patch)

Script pushes a tag to base repository during preparing phase. That's
why `gitremote` option should be the name of the remote name in your
local clone. Newly launched instance will pull repository from
corresponding repository (from a fork if you pass `githubuser`
option).

To login an instance over SSH you need to put your public SSH key to
`install/keys/prod.ssh/authorized_keys` file before deploy.

Make sure you have necessary credentials and access to instance(s) you
need to work with.

## Feature branch deployment

Launches a standalone instance and hosts both application and
services.

Example:

```
./deploy --deploy --config feature --githubuser foo --gitremote fork
```

## Sandbox deployment

Launches a new EC2 instance. Sandbox configuration points to a
predefined host for services.

Example:

```
./deploy --deploy --config sandbox --gitremote upstream
```

### `sandbox` branch

Usual workflow is merging upstream development branch into branch
called `sandbox`. This can be done manually using `git-merge` or by
opening a pull request on GitHub. Merging changes into `sandbox`
branch will start a build job on
[wercker](https://app.wercker.com/#applications/53cd92eedabd120e390b36bd). Build
revision will be deployed to `sandbox` target automatically if build
job succeeds. You can force push the upstream development branch if
`sandbox` is diverged from it.

Alternatively, experimental changes can be pushed to sandbox by
rebasing your changes on top of `sandbox` or upstream development
branch. This is practical if these changes are not breaking or
blocking any other part.

## Debugging

Worker/service configurations are in usual configuration
directory. All configurations contain the necessary information to
find out/traceback how a worker is set up and where (external)
services are located.

Supervisord is managing processes. koding's configuration is located
at `/etc/supervisor/conf.d/koding.conf`.

Logs are located in `/var/log/supervisord` directory. Both `stdout`
and `stderr` are redirected to separate files per job.
