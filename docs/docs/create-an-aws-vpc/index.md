---
layout: doc
title: AWS non-default VPC
permalink: /docs/create-an-aws-vpc
parent: /docs/home
---

# {{ page.title }}

## Introduction

In this guide we will learn more about creating a custom AWS network for our VMs. The main objective of this guide is to show how you can customize your stack template further to define your own network structure and add instances to your network. We will create a high availability service by creating a two tier structure having a single web server and two database instances. Each server will be in different physical location.

![two-tier-vpc.png][1]
Table of contents

* Before we start..
* Full stack
* Steps
    * Creating a stack
    * Edit your stack name
    * Provider
    * Create a VPC
    * Create Subnets
    * Create Internet Gateway
    * Create Route Table
    * Associate route table with our subnets
    * Create Security Group
    * Generate & assign Elastic IPs
    * Create Instances
* Full steps animation
* Build & Test our stack
* Further notes
* Troubleshooting

## Before we start..

It is a good idea to familiarize yourself with [AWS VPC][2] (Virtual Private Cloud) if you are not familiar with it already, please spend sometime to understand its concepts. This will help you greatly to go through this guide of how we create our stack template for our AWS non-default VPC.

We will create a VPC (Virtual Private Cloud) with subnets created in different availability zones _(different physical locations)_ to ensure higher availability. _Learn more about [AWS availability zones][3]_

In this guide we will learn how to create:

1. AWS VPC (Virtual Private Cloud)
2. Subnets
3. Internet Gateway
4. Routing Tables
5. Security Groups
6. Attach Elastic IPs to our VMs
7. Create a VM within a subnet

Our intended structure is to have an AWS non-default VPC (Virtual Private Cloud) with three subnets and three VMs with access to internet:

![VPC network][4]

### Full Stack

This is the full listing of our stack template. Continue reading below to go through the explanation of each section.

```yaml
# This stack will create a two-tier VPC with Elastic IP

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_vpc:
    main:
      cidr_block: 10.0.0.0/16
      instance_tenancy: "default"
      tags:
        Name: 'Koding-VPC'

  aws_subnet:
    subnet1:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1a'
      cidr_block: 10.0.10.0/24
      tags:
        Name: 'Koding-VPC-10.0.10.0'
    subnet2:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1b'
      cidr_block: 10.0.20.0/24
      tags:
        Name: 'Koding-VPC-10.0.20.0'
    subnet3:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1c'
      cidr_block: 10.0.30.0/24
      tags:
        Name: 'Koding-VPC-10.0.30.0'

  aws_internet_gateway:
    internet_gw:
      vpc_id: '${aws_vpc.main.id}'
      tags:
        Name: 'Koding-VPC-internet-gateway'

  aws_route_table:
    internet_rtable:
      vpc_id: '${aws_vpc.main.id}'
      route:
        cidr_block: 0.0.0.0/0
        gateway_id: '${aws_internet_gateway.internet_gw.id}'
      tags:
        Name: 'Koding-VPC-route-table'

  aws_route_table_association:
    subnet1_associate:
      subnet_id: '${aws_subnet.subnet1.id}'
      route_table_id: '${aws_route_table.internet_rtable.id}'
    subnet2_associate:
      subnet_id: '${aws_subnet.subnet2.id}'
      route_table_id: '${aws_route_table.internet_rtable.id}'
    subnet3_associate:
      subnet_id: '${aws_subnet.subnet3.id}'
      route_table_id: '${aws_route_table.internet_rtable.id}'

  aws_security_group:
    security_group:
      name: 'Koding-VPC-sg'
      description: 'Koding VPC allowed traffic'
      vpc_id: '${aws_vpc.main.id}'
      tags:
        Name: 'Koding-allowed-traffic'
      ingress:
        - from_port: 22
          to_port: 22
          protocol: tcp
          cidr_blocks:
            - 0.0.0.0/0
        - from_port: 80
          to_port: 80
          protocol: tcp
          cidr_blocks:
            - 0.0.0.0/0
        - from_port: 56789
          to_port: 56789
          protocol: tcp
          cidr_blocks:
            - 0.0.0.0/0
      egress:
        - from_port: 0
          to_port: 65535
          protocol: tcp
          cidr_blocks:
            - 0.0.0.0/0
  aws_eip:
    team-web-server_eip:
      instance: '${aws_instance.team-web-server.id}'
      vpc: true
    db_master_eip:
      instance: '${aws_instance.db-master.id}'
      vpc: true
    db_slave_eip:
      instance: '${aws_instance.db-slave.id}'
      vpc: true

  aws_instance:
    team-web-server:
      instance_type: t2.micro
      subnet_id: '${aws_subnet.subnet1.id}'
      depends_on: ['aws_internet_gateway.internet_gw']
      vpc_security_group_ids:
        - '${aws_security_group.security_group.id}'
      ami: ''
      tags:
        Name: 'alpha-webserver-${var.koding_user_username}-${var.koding_group_slug}'

    db-master:
      instance_type: t2.micro
      subnet_id: '${aws_subnet.subnet2.id}'
      depends_on: ['aws_internet_gateway.internet_gw']
      vpc_security_group_ids:
        - '${aws_security_group.security_group.id}'
      ami: ''
      tags:
        Name: 'DB-master-${var.koding_user_username}-${var.koding_group_slug}'

    db-slave:
      instance_type: t2.micro
      subnet_id: '${aws_subnet.subnet3.id}'
      depends_on: ['aws_internet_gateway.internet_gw']
      vpc_security_group_ids:
        - '${aws_security_group.security_group.id}'
      ami: ''
      tags:
        Name: 'DB-slave-${var.koding_user_username}-${var.koding_group_slug}'
```

* * *

## Steps

Along the next sections, we will write our stack template section by section showing what each section accomplishes in our network

### Creating a stack

1. Click&nbsp;**Stacks**
2. Click **New Stack**
3. Choose **Amazon** -&gt; Click **Next**
4. Set your AWS credentials in the **Credentials** tab

> For detailed steps on how to create an AWS stack you can refer to [Create AWS Stack][5] guide

> We created our AWS keys in region **EU Ireland (eu-west-1)**, which means our Availability Zones will be relevant to this region. _Learn more about [AWS availability zones][3]_

![regions_01-1.jpg][6]

* * *

### Edit your stack name

A stack name is auto generated when you create a new stack, however if you plan on having multiple stacks, it is a good practice to name your Stack to something you can remember in a glance.

![the-stack-name.png][7]

* * *

### Provider

The first section defines the service provider, usually you wouldn't need to change this part

```yaml
# This stack will create a two-tier VPC with Elastic IP

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
```

* * *

### Create a VPC

Create the VPC network that will contain all our VMs

```yaml
resource:
  aws_vpc:
    main:
      cidr_block: 10.0.0.0/16
      instance_tenancy: "default"
      tags:
        Name: 'Koding-VPC'
```

#### Explanation:

* `resource:`&nbsp;resources section contains **ALL** our created resources (network, instances, configurations...etc.). This is the root header of all our upcoming configurations in all the stack template
    * `aws_vpc:` _we create_ an AWS VPC with the following parameters
        * `main:` _we name this section 'main' since we only have a single VPC (can be any name you wish)_
            * `cidr_block: 10.0.0.0/16` _this defines a VPC network with 65536 private IP addresses_
            * `instance_tenancy: "default"` _we will run our instances on shared hardware. Other option is 'dedicated', learn more about [dedicated instances][8]_
            * `tags:` _header for key:value attributes for our **main** VPC_
                * `name: 'Koding-VPC'` _we define a key-value pair to identify our VPC with a tag. We 'named' our VPC 'Koding-VPC'_

#### Network status:

![network-vpc-begin.png][9]

* * *

### Create subnets

```yaml
aws_subnet:
    subnet1:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1a'
      cidr_block: 10.0.10.0/24
      tags:
        Name: 'Koding-VPC-10.0.10.0'
    subnet2:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1b'
      cidr_block: 10.0.20.0/24
      tags:
        Name: 'Koding-VPC-10.0.20.0'
    subnet3:
      vpc_id: '${aws_vpc.main.id}'
      availability_zone: 'eu-west-1c'
      cidr_block: 10.0.30.0/24
      tags:
        Name: 'Koding-VPC-10.0.30.0'
```

#### Explanation:

* `aws_subnet:` we create our subnets below "**aws_subnet**" header

    * `subnet1:` we name our first subnet "**subnet1**" can be any name you wish

        * `vpc_id: '${aws_vpc.main.id}'` we bind this subnet to be created within our VPC which we created in the "**aws_vpc**" section above. We bind it using the VPC id, which can be fetched following the hierarchy&nbsp;it was created in i.e.: **aws_vpc** _(section head)_ \--&gt; **main** _(our vpc section name)_ \--&gt; **id** _(this is a VPC attribute)_Therefore we use **${aws_vpc.main.id}**
        * `availability_zone: 'eu-west-1a'` we here define which availability zone our subnet will be created in, for our**subnet1** we chose "**eu-west-1a**"
        * `cidr_block: 10.0.10.0/24` we define our subnet IP range to have the IPs 10.0.10.0/24. This allows our subnet to have up to 254 private IP addresses and our VMs in this subnet to start with **10.0.10.XXX**
        * `tags:` header for key:value attributes for our subnet **subnet1**
            * `name: 'Koding-VPC-10.0.10.0'` we define a key-value pair to identify our **subnet1** with a tag. We 'named' our **subnet1** 'Koding-VPC-10.0.10.0' (can be any name you wish)
    * The same goes for our subsequent lines to define the other two subnets "**subnet2**" &amp; "**subnet3**". Note that we defined our subnets with:

        1. Different IPs
        2. Different tags (names)
        3. Different availability zones _(for high availability of our services)_

| Subnet  | IP        | name tag             | Availability Zone |
| ------- | --------- | -------------------- | ----------------- |
| subnet1 | 10.0.10.0 | Koding-VPC-10.0.10.0 | eu-west-1a        |
| subnet2 | 10.0.20.0 | Koding-VPC-10.0.20.0 | eu-west-1b        |
| subnet3 | 10.0.30.0 | Koding-VPC-10.0.30.0 | eu-west-1c        |

_Learn more about [AWS availability zones][3]_

#### Network status:

![Subnets][10]

* * *

### Create Internet Gateway

```yaml
aws_internet_gateway:
  internet_gw:
    vpc_id: '${aws_vpc.main.id}'
    tags:
      Name: 'Koding-VPC-internet-gateway'
```

#### Explanation:

* `aws_internet_gateway:` we create our internet gateway below "**aws_internet_gateway**" header
    * `internet_gw:` we name our internet gateway "**internet_gw**" can be any name you wish
        * `vpc_id: '${aws_vpc.main.id}'` we attach the internet gateway&nbsp;to our VPC created in the "**aws_vpc**" section above. We attach it using the VPC id, which can be fetched by following the hierarchy&nbsp;it was created in i.e.:**aws_vpc** _(section head)_ \--&gt; **main** _(our vpc section name)_ \--&gt; **id** _(this is a VPC attribute)_ Therefore we use**${aws_vpc.main.id}**
        * `tags:` header for key:value attributes for our internet gateway **internet_gw**
            * `name: 'Koding-VPC-internet-gateway'` we define a key-value pair to identify our **internet_gw** with a tag. We 'named' our **internet_gw** 'Koding-VPC-internet-gateway' (can be any name you wish)

#### Network status:

![Internet Gateway][11]

* * *

### Create Route Table

```yaml
aws_route_table:
  internet_rtable:
    vpc_id: '${aws_vpc.main.id}'
    route:
      cidr_block: 0.0.0.0/0
      gateway_id: '${aws_internet_gateway.internet_gw.id}'
    tags:
      Name: 'Koding-VPC-route-table'
```

#### Explanation:

* `aws_route_table:` we create our Route Table below "**aws_route_table**" header
    * `internet_rtable:` we name our Route Table "**internet_rtable**" can be any name you wish
        * `vpc_id: '${aws_vpc.main.id}'` we attach the Route Table to our VPC created in the "**aws_vpc**" section above. We attach it using the VPC id, which can be fetched by following the heirarchy it was created in i.e.: **aws_vpc**(section head) --&gt; **main** (our vpc section name) --&gt; **id** (this is a VPC attribute) Therefore we use**${aws_vpc.main.id}**
        * `route:` the header to define a list of route objects
            * `cidr_block: 0.0.0.0/0` _**required**_ the CIDR block of the route.
            * `gateway_id: '${aws_internet_gateway.internet_gw.id}'` the Internet Gateway ID.
        * `tags:` header for key:value attributes for our internet gateway **internet_gw**
            * `name: 'Koding-VPC-route-table'` we define a key-value pair to identify our **internet_rtable** with a tag. We 'named' our **internet_rtable** 'Koding-VPC-route-table' (can be any name you wish)

#### Network status:

![Route Table][12]

* * *

### Associate route table with our subnets
```yaml
aws_route_table_association:
  subnet1_associate:
    subnet_id: '${aws_subnet.subnet1.id}'
    route_table_id: '${aws_route_table.internet_rtable.id}'
  subnet2_associate:
    subnet_id: '${aws_subnet.subnet2.id}'
    route_table_id: '${aws_route_table.internet_rtable.id}'
  subnet3_associate:
    subnet_id: '${aws_subnet.subnet3.id}'
      route_table_id: '${aws_route_table.internet_rtable.id}'
```

#### Explanation:

`aws_route_table_association:` we create our route table **Associations** below_ "**aws_route_table_association**" header

   * `subnet1_associate:` we name our first association section "**subnet1_associate**", can be any name you wish
       * `subnet_id: '${aws_subnet.subnet1.id}'` we add our subnet (by its ID) to this association. The ID attribute of our first subnet "subnet1" fetched by following the hierarchy it was created in i.e.: **aws_subnet** (section head of our subnet) --> **subnet1** _(our subnet section name)_ \--> **id** (this is a subnet attribute) Therefore we use**'${aws_subnet.subnet1.id}'**
       * `route_table_id: '${aws_route_table.internet_rtable.id}'` we then add our route table ID to complete our association. The ID attribute of our route table "internet_rtable" fetched by following the heirarchy it was created in i.e.: **aws_route_table** (section head of our route table) --> **internet_rtable** (our route table section name) -->**id** (this is a route table attribute) Therefore we use **'${aws_route_table.internet_rtable.id}'**
   * The same goes for our subsequent lines to define the other two subnets associations to our route table **internet_rtable**.

       * _**** Remember**:_ type in the correct subnet **section_id** names (in our example "${aws_subnet.**subnet1**.id}" & "${aws_subnet.**subnet3**.id}") and have a different name for **each** association rule (in our example "subnet2_associate" & "subnet3_associate") as you can see in our stack file

#### Network status:

![Associate route table][13]

* * *

### Create Security Group

We will create a single security group to define our allowed IP &amp; ports ranges for our VMs

```yaml
aws_security_group:
  security_group:
    name: 'Koding-VPC-sg'
    description: 'Koding VPC allowed traffic'
    vpc_id: '${aws_vpc.main.id}'
    tags:
      Name: 'Koding-allowed-traffic'
    ingress:
      - from_port: 22
        to_port: 22
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0
      - from_port: 80
        to_port: 80
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0
      - from_port: 56789
        to_port: 56789
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0
    egress:
      - from_port: 0
        to_port: 65535
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0
```

#### Explanation:

* `aws_security_group:` _we create our security group below_ "**aws_security_group**" _header_

    * `security_group:` _we name our only security group section_ "**security_group**", _can be any name you wish_

        * `name: 'Koding-VPC-sg'` _optional, we name our security group_ "**Koding-VPC-sg**", _can be any name you wish_
        * `description: 'Koding VPC allowed traffic'` _optional, we add a description to our security group_
        * `vpc_id: '${aws_vpc.main.id}'` _optional, the VPC id_
        * `tags:` _header for key:value attributes for our security group **security_group**_
            * `name: 'Koding-allowed-traffic'` _we define a key-value pair to identify our **security_group** with a tag. We 'named' our **security_group** 'Koding-allowed-traffic' (can be any name you wish)_
        * `ingress:` _section for defining all incoming connections IPs & ports to our VMs_

        ```

          - from_port: 22
            to_port: 22
            protocol: tcp
            cidr_blocks:
              - 0.0.0.0/0

        This section contains: - The port ranges (from-to) allowed to access our VMs - **_required_** \- The allowed protocol type`tcp` \- **_required_** \- List of CIDR blocks - _optional_

        For every port/IP range, we need to repeat this section. In our example we allowed ports HTTP (80), SSH (22) & a **required** custom port (56789).

        * **Note:** when defining custom ports make sure you allow port 56789, it is **required to be open** in order for your stack to be built, otherwise Koding for Teams will not be able to access your machines when building your stack and eventually your stack will fail to build.

        * Ingress ports:

          | Type   | Protocol | Port Range | Source    |
          | ------ | -------- | ---------- | --------- |
          | SSH    | TCP      | 22         | 0.0.0.0/0 |
          | HTTP   | TCP      | 80         | 0.0.0.0/0 |
          | Custom | TCP      | 56789      | 0.0.0.0/0 |

        * `egress:` _section for defining all outgoing connections IPs & ports from our VMs_

        ```yaml

          egress:
            - from_port: 0
            to_port: 65535
            protocol: tcp
            cidr_blocks:
              - 0.0.0.0/0


        We allowed all TCP connections on all ports & IPs from our VMs

        * Egress ports:

          | Type | Protocol | Port Range | Destination |
          | ---- | -------- | ---------- | ----------- |
          | All  | TCP      | All        | 0.0.0.0/0   |


* * *

### Generate &amp; assign Elastic IPs

Creating a non-default AWS VPC will not assign public IPs to our VMs, only private IPs. We generate Elastic IPs here and connect them with our instances which we will create in the next section of our Stack Template file.

```yaml
aws_eip:
  team-web-server_eip:
    instance: '${aws_instance.team-web-server.id}'
    vpc: true
  db_master_eip:
    instance: '${aws_instance.db-master.id}'
    vpc: true
  db_slave_eip:
    instance: '${aws_instance.db-slave.id}'
    vpc: true
```

#### Explanation:

* `aws_eip:` _we generate Elastic IPs &amp; assign to VMs below the_ "**aws_eip**" _header_
    * `team-web-server_eip:` _we name our first eip section_ "**team-web-server_eip**", _can be any name you wish_
        * `instance: '${aws_instance.team-web-server.id}'` _we assign the Elastic IP to an instance called "team-web-server" as defined in the next section of our stack template_
        * `vpc: true` _a Boolean indicating if the EIP is in a VPC or not - optional_

***

### Create Instances

This is our last section of our VPC Stack template, we now have everything related to the network set and only waiting for our VMs to be created. As mentioned before we will create a single instance in each subnet.

```yaml

aws_instance:
  team-web-server:
    instance_type: t2.micro
    subnet_id: '${aws_subnet.subnet1.id}'
    depends_on: ['aws_internet_gateway.internet_gw']
    vpc_security_group_ids:
      - '${aws_security_group.security_group.id}'
    ami: ''
    tags:
      Name: 'alpha-webserver-${var.koding_user_username}-${var.koding_group_slug}'

  db-master:
    instance_type: t2.micro
    subnet_id: '${aws_subnet.subnet2.id}'
    depends_on: ['aws_internet_gateway.internet_gw']
    vpc_security_group_ids:
      - '${aws_security_group.security_group.id}'
    ami: ''
    tags:
      Name: 'DB-master-${var.koding_user_username}-${var.koding_group_slug}'

  db-slave:
    instance_type: t2.micro
    subnet_id: '${aws_subnet.subnet3.id}'
    depends_on: ['aws_internet_gateway.internet_gw']
    vpc_security_group_ids:
      - '${aws_security_group.security_group.id}'
    ami: ''
    tags:
      Name: 'DB-slave-${var.koding_user_username}-${var.koding_group_slug}'
```

#### Explanation:

* `aws_instance:` _we create our VMs below the_ "**aws_instance**" _header_

    * `team-web-server:` _we name our first VM section_ "**team-web-server**", _can be any name you wish_
        * `instance_type: t2.micro` we define the machine type for our VM
        * `subnet_id: '${aws_subnet.subnet1.id}'` we choose to create this VM in **subnet1** by its ID. Note that "**subnet1**" in ${aws_subnet.**subnet1**.id} is the section name **as we defined it** in the aws_subnet section. Replace subnet1 with the name you chose if you named this section differently.
        * `depends_on: ['aws_internet_gateway.internet_gw']` We make sure this VM is connected to the internet via our defined internet gateway by making use of the argument `depends_on`
        * `vpc_security_group_ids:` we assign the relevant security group(s) to our VM, this argument **takes a list** of security groups if we have more than one. In our case we have only one.
            * `\- '${aws_security_group.security_group.id}'` the security group we created earlier mentioned by its ID
        * `ami: ''` the AMI to use for the instance, we left it since we don't want any.
        * `tags:` header for key:value attributes for our VM **team-web-server**
            * `Name: 'alpha-webserver-${var.koding_user_username}-${var.koding_group_slug}'` we define a key-value pair to identify our VM with a tag on Amazon. We 'named' our VM **alpha-webserver-alison40-pied-piper**. We made use of the variables "${var.koding_user_username}" which fetches the user name, and the variable "${var.koding_group_slug}" our team name in Koding for Teams.
* The same goes for our subsequent lines to define the other two VMs "**db-master**" &amp; "**db-slave**". Note that we defined our VMs in different subnets and with different name tags

      | VM              | subnet  | name-tag                            |
      | --------------- | ------- | ----------------------------------- |
      | team-web-server | subnet1 | alpha-webserver-alison40-pied-piper |
      | db-master       | subnet2 | db-master-alison40-pied-piper       |
      | db-slave        | subnet3 | db-slave-alison40-pied-piper        |

#### Network status:

![Instances][14]

* * *

### Full steps visualized

These are the steps we moved through to create our AWS non-default VPC:

![Full steps animation][15]

* * *

### Build &amp; Test our stack

Let's now start to build our stack to test our stack template file

#### Save &amp; test the stack template

Click **Save**, your stack should build successfully. If there are any errors you will need to attend to them before building your stack.

![VPC success2][16]

#### Build Stack

Click **Initialize**&nbsp;and close your stack template, follow the step by step modal to build your Stack.&nbsp;

![Stack building][17]

#### Successful&nbsp;build!

The three VMs are now ready, you and your team can now use your new stack template&nbsp;to build your environments and start Koding!

![all-built.png][18]

* * *

### Further Notes

Congratulations, you have now learned how to build an AWS non-default VPC for your team. You can further experiment and test your stack file. You might want to consider building your VM's ready with the packages required for Each VM. You can make use of the `user_data` header. i.e. install Apache on webserver and MySQL or Postgres on your DB instances. _You can refer to **Modifying user_data section**&nbsp;in our "[**Advanced stack editing**][19]" guide._

* * *

### Troubleshooting

* Read carefully the error output when you click **Save &amp; Test**
* Make sure your stack file indentation is correct
* If your stack file saves correctly but building the stack fails, check the error returned when the build fails. Also make sure the correct ports are open in all your machines. If in doubt, allow all then test again.
* If you are trying an `apt-get install` or `apt-get update` and it fails, make sure this VM/subnet has access to the internet through an internet gateway!
* Review the stack built on AWS if you need to troubleshoot from the "Back-end"

[1]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/two-tier-vpc.png
[2]: https://aws.amazon.com/documentation/vpc/
[3]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
[4]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-full.png
[5]: /docs/creating-an-aws-stack
[6]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/regions_01-1.jpg
[7]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/the-stack-name.png
[8]: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/dedicated-instance.html
[9]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-vpc-begin.png
[10]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-subnets.png
[11]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-ig.png
[12]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-route-table.png
[13]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-assoc.png
[14]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-instances.png
[15]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/network-steps-animation.gif
[16]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/VPC-success2.png
[17]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/all-building.png
[18]: {{ site.url }}/assets/img/guides/stack-aws/3-aws-vpc/all-built.png
[19]: /docs/database-vm-schema-setup#modify-user-data
