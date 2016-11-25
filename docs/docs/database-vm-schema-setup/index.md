---
layout: doc
title: Advanced stack editing
permalink: /docs/database-vm-schema-setup
parent: /docs/home
---

# {{ page.title }}

## Introduction

In this example we will create a **Stack** with a single VM acting as a database server. In this example we will cover:

1. Creating a Stack
2. Editing Stack `user_data` section to install MySQL server whenever a VM is built
3. Using **Custom Variables** to create a database table and to place a file in user's home folder

### Table of contents

1. [Full stack](#full-stack)
3. [Steps](#steps)
    1. [Creating a stack](#create-stack)
    2. [Edit your stack name](#edit-stack-name)
    3. [Edit your VM name](#edit-vm-name)
    4. [Modify the `user_data` section](#user-data)
    5. [Create a `variable` section](#var-section)
    6. [Update the `user_data` section](#update-user-data)
4. [Build & Test our stack](#build-stack)
5. [Test our Stack](#test)
6. [Conclusion](#conclusion)


## <a id="full-stack"></a>Full Stack

If you want to skip the explanation, here is how your final Stack template will look:

```yaml
# This stack file will build a MySQL Database VM
# and will run a SQL script to create database and a table schema

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'

variable:
  my_DB_construct:
    default: 'create database customer_accounts;use customer_accounts;create table customers(CustomerID int,LastName varchar(255),FirstName varchar(255),Address varchar(255),Phone varchar(255),PRIMARY KEY (`CustomerID`));'

resource:
  aws_instance:
    db_server:
      instance_type: t2.micro
      user_data: |-
        DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y mysql-server-5.6
        echo '${var.my_DB_construct}' > /home/${var.koding_user_username}/dbconstruct.sql
        mysql -u root "" < /home/${var.koding_user_username}/dbconstruct.sql
```

## <a id="steps"></a>Steps

### <a id="create-stack"></a>Create a stack

1. Click **Stacks**
1. Click **New Stack**
1. Choose **Amazon Web Services** -> Click **Next**
1. Set your AWS credentials in the **Credentials** tab

> For a step by step guide on how to create an AWS stack [check here][20]


### <a id="edit-stack-name"></a>Edit your stack name

It is a good practice to name your Stack, specially if you plan to have multiple stacks. We named our stack "DB server alpha"

![rename-stack-894.png][1]

### <a id="edit-vm-name"></a>Edit your VM name

Let us also rename our VM to something more descriptive, the name of the VM is defined under the `aws_instance:` header. In our case we chose the name '_db_server_'.

``` yaml
resource:
  aws_instance:
    db_server: # name changed to 'db_server'
      instance_type: t2.micro
```

### <a id="user-data"></a>Modify the `user_data` section

We will add commands to the `user_data` section to install MySQL. The `user-data` section contains the commands we want to run when the VM is first built. All commands here run as `root`. In our example, we want to:

1. Update packages list
2. Install MySQL unattendedly

```yaml
    user_data: |-
            DEBIAN_FRONTEND=noninteractive
            apt-get update -y
            apt-get install -y mysql-server-5.6
```

* Using the pipe dash "&#124;-" after the `user_data:` header will allow you to write your commands on several lines (multi-lines)

### <a id="var-section"></a>Create a `variable` section

We will now create a variable in our **Stack** file. This variable will hold our table schema example. (_Later on, we will call this variable to create the Database table on the VM after MySQL is installed._)

The database schema we will use is:

```yaml
create database customer_accounts;
    use customer_accounts;
    create table customers
    (
        CustomerID int,
        LastName varchar(255),
        FirstName varchar(255),
        Address varchar(255),
        Phone varchar(255),
        PRIMARY KEY (`CustomerID`)
    );
```

We create the **`variable:`** section between the `provider` and the `resource` sections. We define a variable name (`my_DB_construct`) and set its default value to our db schema string:

```yaml
variable:
   my_DB_construct:
     default: 'create database customer_accounts;use customer_accounts;create table customers(CustomerID int,LastName varchar(255),FirstName varchar(255),Address varchar(255),Phone varchar(255),PRIMARY KEY (`CustomerID`));'
```

### <a id="update-user-data"></a>Update the `user_data` section

We will update the **user_data** section to create our database schema and save the schema in a file in the user home directory. This will show how variables are placed in our **Stack Template**

```yaml
user_data: |-
    DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y mysql-server-5.6
    echo '${var.my_DB_construct}' > /home/${var.koding_user_username}/dbconstruct.sql
    mysql -u root "" < /home/${var.koding_user_username}/dbconstruct.sql
```

* `echo '${var.my_DB_construct}' > /home/${var.koding_user_username}/dbconstruct.sql`
  * This line will dump the value of the variable **${var.my_DB_construct}**, our database schema, into a file named **dbconstruct.sql**
  * We also made use of the variable **${var.koding_user_username}**, which holds the username of the user logged in to Koding, to add the file to the user home directory using the absolute path.
* `mysql -u root "" < /home/${var.koding_user_username}/dbconstruct.sql`
  * We login to MySQL using root user and use the **dbconstruct.sql** file as input to MySQL to create our database.

### <a id="build-stack"></a>Let's build our Stack & test!

1. Click **SAVE**, you should see the message that your stack was built successfully if all is well.

    ![stack-build-success.png][2]

2. Click **Make Team Default**, this will populate your stack to the team and send them updates that a new stack is in place.

    ![share-creds-854.png][3]

    Choose whether you wish to enable the checkbox _share your credentials with the team_, then click **Share with the team**

    > Sharing your credentials with your team is very helpful if you don't want your team (_developers/students_) to go through creating an AWS account each, or if you want to have full control over the machines created in AWS.

    > Sharing your AWS credentials means all built machines will be under your AWS account, which will incur charges to your AWS account for each machine built by your team.

3. <a id="init-stack"></a>Click **Initialize**

    > **If you are updating an _already_ created stack, please note:**
    Any data that was on your earlier Stack VM's will be removed when you choose to _build/re-initialize_ the new stack this also applies to your teammates when they click build/re-initialize new stack. When a user chooses to Build the new Stack all their VM's will be re-initialized as complete new VM's with the new configuration from your stack template. A warning will pop up to alert the user about this before continuing to build the new stack. Please make sure to backup your data before building your new stack in that case!

4. The Build Your Stack modal will open, click **Next**

    ![build-stack-step1.png][4]

    > Noticed the **Read Me First** content? This is the readme that is defined by default when creating a stack, you can edit its content from the **Readme tab** during Stack creation.

5. Choose the credentials you want to use with your stack and click **Build Stack**

    ![build-stcak-step2.png][5]

6. Stack building will start..

    ![build-stack-inprogress.png][6]

7. Successfully built stack, click **Start Coding**

    ![build-success.png][7]

8. **user-data** commands still running

    ![stack-running-commands-zoom.png][8]

    **user-data** commands complete we can now start using our VM(s)

    ![10-commands-finished-zoom.png][9]

9. <a id="test"></a>Let us check if our `user_data` commands ran successfully. If all went well, we should be able to see the file **dbconstruct.sql** created, and that it contains our DB Schema, MySQL installed, and the _**customer_accounts**_ database created with a _**customer**_ table as defined in our DB schema file. Here's a reminder of our `user_data `block from our Stack Template

```yaml
user_data: |-
    DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y mysql-server-5.6
    echo '${var.my_DB_construct}' > /home/${var.koding_user_username}/dbconstruct.sql
    mysql -u root "" < /home/${var.koding_user_username}/dbconstruct.sql
```
  - Let's first see if the file **dbconstruct.sql** was created and that it contains our DB schema commands as we defined it in our `variable` block.

  ![11-check-files-zoom-1.png][10]

  _Yes! all is well, the file exists in our Files viewer section in Koding, or by typing in the `ls` command._

  - Opening the file shows that our variable content was dumped in the file as we expected

  ![12-review-files-zoom2-1.png][11]

  - Time to check if MySQL database was installed and our **customer_accounts** database and table **customers** created successfully.

    _MySQL has been installed_

    ![13-mysql-zoom.png][12]

    _Our **customer_accounts** database created successfully_

    ![14-database-zoom.png][13]

    _Our **customers** table created successfully_

    ![15-tables-zoom-1.png][14]

    _Our **customers** schema is in place_

    ![16-tables-ready-zoom.png][15]

## <a id="conclusion"></a>Conclusion

Congratulations! you are now ready to create customized Stack files to install packages and use variables to help you setup your VMs. You are now sure all your team have the same exact setup. Onboarding a new team member is now a breeze, all they need to do is get invited to the team and start their stack!

Happy Koding!

[1]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/rename-stack-894.png
[2]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/stack-build-success.png
[3]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/share-creds-854.png
[4]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/build-stack-step1.png
[5]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/build-stcak-step2.png
[6]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/build-stack-inprogress.png
[7]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/build-success.png
[8]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/09-stack-running-commands-zoom.png
[9]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/10-commands-finished-zoom.png
[10]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/11-check-files-zoom-1.png
[11]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/12-review-files-zoom2-1.png
[12]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/13-mysql-zoom.png
[13]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/14-database-zoom.png
[14]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/15-tables-zoom-1.png
[15]: {{ site.url }}/assets/img/guides/stack-aws/2-db-schema/16-tables-ready-zoom.png
[20]: {{ site.url }}/docs/creating-an-aws-stack
