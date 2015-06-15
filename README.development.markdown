# Life cycle of a development task

It consists of following steps:


- Estimation

- Starting

- Submitting a pull request & review

- Deployment

- Testing

## Story types

#### Feature

This type of stories are used for implementing new features. Stories
are added to
[features](https://www.pivotaltracker.com/n/projects/1167412) project.

#### Bug

This type of story is used for broken functionalities.  Stories are
added to [bugs](https://www.pivotaltracker.com/n/projects/1217662)
project.

#### Chore

This type is used for maintenance tasks that does not implement a new
feature or fix/improve an existing functionality.

#### Epic

Epic is a collection of stories. Epics are recommended to group tasks
that fall under a single objective.


## Estimation

First thing to do is setting an estimation point to story.

- 0 point is used for trivial stories that can be done in like no-time
  or already done.

- Use 1 point for a story that can be completed in a day.

- Use 2 points for a story that is going to take more than a day to
  complete.

- Use 3 points for a story that needs to be broken down for a more
  fine estimation. Never start working on a 3 pointer story.

## Starting

Starting is the most easy part of this cycle.  If you need to switch
to some other task or cannot proceed then you should put that task
into unstarted state.

You can add a goal entry to iDoneThis, preferrably by backlinking
story.

## Development

* Your code should have decent amount of comments ( not only function comments but also inline )
* Your code should have good coverage of tests of integration and unit (+%70)
* Your code should be formatted accordingly ( go/coffee style guides )
* If your code/feature requires a UI test, inform QA team with steps & and feature to test at devs@koding.com
* If your code requires a metric for alerting and/or monitoring, inform at sysops@koding.com
* If your code requires a system/server change, do it in your code
* if your code requires an API change, do it as backward compatible ( do not remove any API right away even if it is obsolete, do it with another deploy )
* Feature you develop, SHOULD be testable in dev env too without needing to take any extra step
* If your code requires a db migration, you _must_ do it with backward compatible steps
* do not apply database changes without having anyone to review them
* notify others at koding channel if your are gonna apply a blocking/performance degrading change
* Use logging in your code wisely, do not output lines that make sense only for you. Know the difference between debug&info&critical&error&fatal
* If your code requires a new Go package, open a separate PR containing only that package, all added Go packages should be reviewed too.
* DO NOT open a PR with LOTS of code in it, after stating your intentions & architecture to the reviewer, do open small, incremental PRs
* Do not come and say, i used a new feature of a tool we use and you all need to update your X to version Y
* instead do
  * test it thoroughly in your local for a while,
  * request one of your colleagues to use that specific version along with you,
  * update dev scripts to enforce dev env to use that version,
  * add help text on how to update it,
  * update wercker boxes
  * update test boxes
  * update elasticbeanstalk env scripts to use them
  * deploy your changes separately from normal schedule if it can break deployments


### Making changes in submodules

Following paths are submodules owned by koding in
[koding/koding](http://github.com/koding/koding) repository.

- client/ide
- client/finder
- client/landing

Add your fork of submodule as a remote in local clone.

```shell
cd $SUBMODULE_PATH
git remote add -f fork git@github.com/$USERNAME/$SUBMODULE_NAME.git
```

You should checkout to most recent revision of upstream development
branch (it is `master` most of the time) in your local clone of a
submodule before you start making changes.

```shell
git remote update
git checkout $BRANCH_NAME # if necessary
git rebase origin/master
```

### Making changes in a node module

Most notable node module in place is KD framework.

To begin working on a node module, make sure you have a local clone on
your development environment.  It shouldn't be in koding repository
clone.

Setup your fork's remote in local clone where changes you make will be
pushed first.

```shell
cd $MODULE_PATH
npm link
```

`npm link` command makes your local clone available in the module
search path of `node` runtime.  It basically links module path into
global node modules library directory
(e.g. /usr/local/lib/node_modules).

First thing to do is setting up your local clone as a node module in
your koding development environment.  There are a few packages that
require node modules you can work with.

- main (koding repository)
- client
- client/builder
- client/landing

You need to change shell's working directory to one of these packages
which depends on node module you're going to work on.  That is denoted
as PACKAGE_DIR environment variable in the below command excerpt.

```shell
cd $PACKAGE_DIR
npm link $MODUlE_NAME
```

`npm link $MODULE_NAME` command above installs your local clone into
parent package as a dependency which will effectively make your
changes in node module repository visible in your koding development
environment.

#### Versioning of node modules

It's necessary to keep track of versions both on `npm` registry and
repository tags.  Please follow patterns used in prior versions of
that package to name versions.

Module versions needs to be updated after are accepted.  Process to do
this is explained in following steps:

- Version in `package.json` file needs to be increased, committed and
  pushed to upstream repository

- Tag new version in `git` repository and push to upstream repository

- Execute module prepublish script or `make` targets to make sure
  module is not broken

- Publish new version to module to npm registry

## Submitting a pull request & review

You need to submit your changes as a pull request on GitHub.  A story
is considered in progress until pull request is accepted.  Feature/bug
type of stories requiring a code change should not be finished
manually.  You can put a checkmark respective iDoneThis entry at this
point.

One of the following keywords needs to be added to end of pull request
title.

- Completes for feature stories

- Fixes for bug stories

Example: “Implement foo feature [completes #123456]”. #123456 is the
story id on Pivotal Tracker.

Backlink pull request on GitHub to story on Pivotal Tracker and
vice-versa.

Attach a screenshot/screencast of visual changes into pull request to
make review process easier.

There are automated tests executed for open pull requests determining
CI status of your changes.

### Submitting a pull request to a submodule

You should push your commits to your own fork of a submodule then open
a pull request.

It's imperative to **update** submodule revision in main repository
after your submodule pull request is accepted.

Submit a pull request to main repository updating submodule revision.

```shell
cd $SUBMODULE_PATH
git checkout $UPSTREAM_BRANCH_NAME # it'll be `master` most of the time
git remote update
git reset --hard origin/$UPSTREAM_BRANCH_NAME
cd $KODING_PATH
git add $SUBMODULE_PATH
git commit -m "Update $SUBMODULE_NAME submodule"
```

Push that commit to your main repository fork and then open a pull
request.

## Deployment

Regular deployments are done in Tuesday and Friday, starting at 6am
UTC.  QA team delivers finished tasks on Pivotal Tracker as first step
to testing phase.

Please ensure that your pull requests are **merged** before
deployments start.  If this means you need to _nudge_ a pull request
reviewer because your pull request is pending merge, do so!

## Testing

QA team tests delivered stories on
[sandbox](https://sandbox.koding.com) and
[latest](https://latest.koding.com) environments.  If a story does not
satisfy requirements then it will be rejected.  You need to restart
that story when you begin working on it again and follow same steps.
