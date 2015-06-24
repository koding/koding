Terraform
=========

-	Website: http://www.terraform.io
-	IRC: `#terraform-tool` on Freenode
-	Mailing list: [Google Groups](http://groups.google.com/group/terraform-tool)

![Terraform](https://raw.githubusercontent.com/hashicorp/terraform/master/website/source/assets/images/readme.png)

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

The key features of Terraform are:

-	**Infrastructure as Code**: Infrastructure is described using a high-level configuration syntax. This allows a blueprint of your datacenter to be versioned and treated as you would any other code. Additionally, infrastructure can be shared and re-used.

-	**Execution Plans**: Terraform has a "planning" step where it generates an *execution plan*. The execution plan shows what Terraform will do when you call apply. This lets you avoid any surprises when Terraform manipulates infrastructure.

-	**Resource Graph**: Terraform builds a graph of all your resources, and parallelizes the creation and modification of any non-dependent resources. Because of this, Terraform builds infrastructure as efficiently as possible, and operators get insight into dependencies in their infrastructure.

-	**Change Automation**: Complex changesets can be applied to your infrastructure with minimal human interaction. With the previously mentioned execution plan and resource graph, you know exactly what Terraform will change and in what order, avoiding many possible human errors.

For more information, see the [introduction section](http://www.terraform.io/intro) of the Terraform website.

Getting Started & Documentation
-------------------------------

All documentation is available on the [Terraform website](http://www.terraform.io).

Developing Terraform
--------------------

If you wish to work on Terraform itself or any of its built-in providers, you'll first need [Go](http://www.golang.org) installed on your machine (version 1.4+ is *required*). Alternatively, you can use the Vagrantfile in the root of this repo to stand up a virtual machine with the appropriate dev tooling already set up for you.

For local dev first make sure Go is properly installed, including setting up a [GOPATH](http://golang.org/doc/code.html#GOPATH). Next, install the following software packages, which are needed for some dependencies:

-	[Git](http://git-scm.com/)
-	[Mercurial](http://mercurial.selenic.com/)

Next, clone this repository into `$GOPATH/src/github.com/hashicorp/terraform`. Install the necessary dependencies by running `make updatedeps` and then just type `make`. This will compile some more dependencies and then run the tests. If this exits with exit status 0, then everything is working!

```sh
$ make updatedeps
...
$ make
...
```

To compile a development version of Terraform and the built-in plugins, run `make dev`. This will put Terraform binaries in the `bin` and `$GOPATH/bin` folders:

```sh
$ make dev
...
$ bin/terraform
...
```

If you're developing a specific package, you can run tests for just that package by specifying the `TEST` variable. For example below, only`terraform` package tests will be run.

```sh
$ make test TEST=./terraform
...
```

### Acceptance Tests

Terraform also has a comprehensive [acceptance test](http://en.wikipedia.org/wiki/Acceptance_testing) suite covering most of the major features of the built-in providers.

If you're working on a feature of a provider and want to verify it is functioning (and hasn't broken anything else), we recommend running the acceptance tests. Note that we *do not require* that you run or write acceptance tests to have a PR accepted. The acceptance tests are just here for your convenience.

**Warning:** The acceptance tests create/destroy/modify *real resources*, which may incur real costs. In the presence of a bug, it is technically possible that broken providers could corrupt existing infrastructure as well. Therefore, please run the acceptance providers at your own risk. At the very least, we recommend running them in their own private account for whatever provider you're testing.

To run the acceptance tests, invoke `make testacc`:

```sh
$ make testacc TEST=./builtin/providers/aws TESTARGS='-run=Vpc'
go generate ./...
TF_ACC=1 go test ./builtin/providers/aws -v -run=Vpc -timeout 90m
=== RUN TestAccVpc_basic
2015/02/10 14:11:17 [INFO] Test: Using us-west-2 as test region
[...]
[...]
...
```

The `TEST` variable is required, and you should specify the folder where the provider is. The `TESTARGS` variable is recommended to filter down to a specific resource to test, since testing all of them at once can take a very long time.

Acceptance tests typically require other environment variables to be set for things such as access keys. The provider itself should error early and tell you what to set, so it is not documented here.
