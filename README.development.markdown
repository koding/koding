  * [Getting started for local deployment](#getting-started-for-local-deployment)
      * [Prerequisites](#prerequisites)
      * [Install dependencies](#install-dependencies)
      * [Deploy Koding locally](#deploy-koding-locally)
  * [Life cycle of a development task](#life-cycle-of-a-development-task)
    * [Story types](#story-types)
        * [Feature](#feature)
        * [Bug](#bug)
        * [Chore](#chore)
        * [Epic](#epic)
    * [Estimation](#estimation)
    * [Starting](#starting)
    * [Development](#development)
      * [Making changes in submodules](#making-changes-in-submodules)
      * [Making changes in a node module](#making-changes-in-a-node-module)
        * [Versioning of node modules](#versioning-of-node-modules)
      * [Implementing a Kloud provider plugin](#implementing-a-kloud-provider-plugin)
    * [Submitting a pull request &amp; review](#submitting-a-pull-request--review)
      * [Submitting a pull request to a submodule](#submitting-a-pull-request-to-a-submodule)
    * [Deployment](#deployment)
    * [Testing](#testing)
    * [Amazon Server Management](#amazon-server-management)
      * [VPC](#vpc)
      * [Subnets](#subnets)
      * [Routing Tables](#routing-tables)
      * [Internet Gateways](#internet-gateways)
      * [Elastic IPs](#elastic-ips)
      * [Network ACLs](#network-acls)
      * [Security Group](#security-group)

# Getting started for local deployment

### Prerequisites

- [Homebrew](http://brew.sh/)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Go](https://golang.org/dl/) (**Mac users**: use official installer)

### Install dependencies

Supported `node.js` and `npm` versions are respectively `0.10` and `2.x` - if you have already newer version installed, remember to force remove it first:

```
$ brew remove node --force
$ brew tap homebrew/versions
$ brew install homebrew/versions/node010
```

```
$ brew install docker graphicsmagick mongodb nginx postgresql
$ npm i coffee-script@1.12.2 gulp -g
```

### Deploy Koding locally

```
koding $ npm install
koding $ ./configure
koding $ ./run buildservices force
koding $ ./run install
koding $ ./run backend
```

Access your local deployment under `dev.koding.com:8090` (`dev.koding.com` is added to your routing table during deploy and routes to `localhost`).

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
* Do not push any credential, authrization key, public/private key pairs,
secret key, password or similar sensitive information that is used in production
systems to main koding/koding repository. If you need to add new configuration
parameters let `on call` person to help you with setting it to credential repo.

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

Module version needs to be updated after changes are accepted.
Process to do this is explained in following steps:

- Version in `package.json` file needs to be increased, committed and
  pushed to upstream repository

- Tag new version in `git` repository and push to upstream repository

- Execute module prepublish script or `make` targets to make sure
  module is not broken

- Publish new version to module to npm registry

### Implementing a Kloud provider plugin

The Kloud provider design, instructions on how to implement
custom provider plugin and working example live in an external
repository.

  https://github.com/koding/kloud-provider-example

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


## Amazon Server Management

### VPC

Amazon Virtual Private Cloud (Amazon VPC) lets you provision a logically
isolated section of the Amazon Web Services (AWS) Cloud where you can launch AWS
resources in a virtual network that you define. You have complete control over
your virtual networking environment, including selection of your own IP address
range, creation of subnets, and configuration of route tables and network
gateways.

* Newly created VPCs should start with "vpc" prefix



### Subnets

Subnets are logical partitions within VPC, they are limited by their
Availabilty Zones

* All subnets should start with "subnet" prefix. Should be
followed by region suffix then should have vpc name eg:subnet-1a-koding-eb-
deployment-prod :subnet-<region>-<vpc_name>

### Routing Tables

A route table contains a set of rules, called routes, that are used to determine
where network traffic is directed.

* They should start with "rtb" prefix, followed by vpc name
eg: rtb-koding-eb-deployment-prod :rtb-<vpc_name>

* Do not assign any subnets to main route tables, for security reasons

### Internet Gateways

An Internet gateway is a horizontally scaled, redundant, and highly available
VPC component that allows communication between instances in your VPC and the
Internet. It therefore imposes no availability risks or bandwidth constraints on
your network traffic. An Internet gateway serves two purposes: to provide a
target in your VPC route tables for Internet-routable traffic, and to perform
network address translation (NAT) for instances that have been assigned public
IP addresses.

To enable access to or from the Internet for instances in a VPC subnet, you must
attach an Internet gateway to your VPC, ensure that your subnet's route table
points to the Internet gateway, ensure that instances in your subnet have public
IP addresses or Elastic IP addresses, and ensure that your network access
control and security group rules allow the relevant traffic to flow to and from
your instance.

* They should start with "igt", followed by vpc name
eg: igw-koding-eb-deployment-prod : igw-<vpc_name>

* they should be attached to one VPC

### Elastic IPs

An Elastic IP address (EIP) is a static IP address designed for dynamic cloud
computing. With an EIP, you can mask the failure of an instance or software by
rapidly remapping the address to another instance in your account. Your EIP is
associated with your AWS account, not a particular instance, and it remains
associated with your account until you choose to explicitly release it.

* They should be attached to one instance

### Network ACLs

A network access control list (ACL) is an optional layer of security that acts
as a firewall for controlling traffic in and out of a subnet. You might set up
network ACLs with rules similar to your security groups in order to add an
additional layer of security to your VPC

* They should start with "acl", followed by vpc name
eg: acl-koding-eb-deployment-prod :acl-<vpc_name>

* They should be attached to one at least one subnet

### Security Group

A security group acts as a virtual firewall for your instance to control inbound
and outbound traffic. When you launch an instance in a VPC, you can assign the
instance to up to five security groups. Security groups act at the instance
level, not the subnet level. Therefore, each instance in a subnet in your VPC
could be assigned to a different set of security groups. If you don't specify a
particular group at launch time, the instance is automatically assigned to the
default security group for the VPC.

* You can create up to 100 security groups per VPC. You can add up to 50 rules to
each security group. If you need to apply more than 50 rules to an instance, you
can associate up to 5 security groups with each network interface. For more
information about network interfaces, see Elastic Network Interfaces (ENI).

* You can specify allow rules, but not deny rules.

* You can specify separate rules for inbound and outbound traffic.

* By default, no inbound traffic is allowed until you add inbound rules to the
security group.

* By default, all outbound traffic is allowed until you add outbound rules to the
group (and then, you specify the outbound traffic that's allowed).

* Responses to allowed inbound traffic are allowed to flow outbound regardless of
outbound rules, and vice versa (security groups are therefore stateful).

* Instances associated with a security group can't talk to each other unless you
add rules allowing it (exception: the default security group has these rules by
default).

* After you launch an instance, you can change which security groups the instance
is associated with.

* VPC automatically comes with a default security group. Each EC2 instance
that you launch in your VPC is automatically associated with the default
security group if you don't specify a different security group when you launch
the instance.

* You can change the rules for the default security group. But dont do it

* You can't delete a default security group.

* All security groups should tagged with a proper type
Types are ssh, loadbalancer, personal, eb, other, default

* `ssh` types security groups are automatically populated security groups from
`personal` tagged security groups

* `loadbalancer` typed security groups should only have 2 ingress rules, 80 & 443,
they cant have more than 2

* `loadbalancer` typed security groups should only have 2 egress rules, 80, 81,
they cant have more than 2

*  `personal` typed security groups are special security groups for developers
with SSH access, you can create as many as security groups with `type=personal`
tag, should only have 2 ingress 1 egress rules at most.

* `eb` typed security groups are for Elastic Beanstalk environments and their
internal & external communications, they can be reached from their respective
LoadBalancer security groups. Latest EB SG has also production ELB SG because we
are using latest environemnt for 0 downtime deployment/switch

* `eb` should include, loadbalancer sg, default sg, and itself (for internal comm)

* `other` typed security groups can only have 22, 80 and 443 as ingress rule,
egress is limited with one rule.

* `default` typed security groups are created when a vpc is created, do no use
them for your very own purposes, you can not delete them either.

* Security groups should start with `sg` prefix, should be followed by their
respective vpc name, resource name and type

eg: sg-koding-eb-deployment-prod--koding-prod-eb: sg-<vpc_name>--<resource_name>-<type>

Things to watch out while creating machines;
* Assing proper security groups
* Do no create random security groups
* Name security groups properly


# Project Management
[Jira](https://koding.atlassian.net/)
