# mig-deploy

Ansible playbooks and associated CloudFormation templates to deploy a MIG
environment into AWS.

A few CloudFormation templates exist which depend on each other, so the
order of playbook execution is important.

See variables in ``vars/vars-<env>.yml`` for variables that can be changed to
modify playbook execution.

## Playbooks

### role

Stack creates a new MIG instance IAM role that will be associated with MIG
EC2 instances. The role is assigned read permissions for `mig/*` under
`sopss3arn`. When instances are launched they will fetch various environment
specific configuration data from this S3 bucket that is used when the instance
configures itself. The file in S3 should be called `mig-sec-dev.yml` for a
development environment, or `mig-sec-prod.yml` for a production environment.

See [doc/example-sec-env.yml](doc/example-sec-env.yml) for an example of what
the contents of this file should be and how it should be encrypted using
[sops](https://github.com/mozilla/sops).

Once the role stack is deployed, ensure the new instance role is assigned permissions
to decrypt data using the KMS ARN used for sops encryption in the account, as
sops will make use of the instance role to decrypt the file stored in S3 to configure
the instance.

### logging

Stack creates SNS and SQS resources which instances deployed using the other roles
will log to using td-agent.

### base

Stack creates the base MIG VPC, associated subnets, and NAT instance.

### rds

Stack creates a Postgres RDS instance which will host the MIG database. When
new stacks are created to replace an old stack, generally a new `rds`,
and `app` stack will be created. We require a new `rds` stack as currently
it is not possible to share the same database instance between multiple running
instances of the scheduler. This role supports supplying a database snapshot
identifier `dbsnapshotid`. You can create a snapshot of a current database instance,
and supply the snapshot name here to import the data into the new RDS instance as
part of an update.

### app

Stack deploys the MIG application, including the API, scheduler, and relays.

## First deployment

The playbooks are organized to deploy either a development environment, or a
production environment. This section will use deployment of production as an
example.

### Edit environment specific configuration

Edit [vars/vars-prod.yml](vars/vars-prod.yml), change it as needed. These variables are passed as
parameters to the various CloudFormation templates, and control playbook execution.

[vars/sec-prod.yml](vars/sec-prod.yml) is an `ansible-vault` protected file that only contains
the initial RDS administrator password, and is used for first deployment when
creating the database.

### Create sops secrets and upload to s3

An example sops secrets yml file is included at [doc/example-sec-env.yml](doc/example-sec-env.yml).
This should be edited, encrypted using the relevant KMS key, and uploaded to S3 in the
bucket location indicated in the environment specific configuration.

### Create initial stacks

```
ansible-playbook playbooks/role.yml --extra-vars env=prod
ansible-playbook playbooks/logging.yml --extra-vars env=prod
ansible-playbook playbooks/base.yml --extra-vars env=prod
ansible-playbook playbooks/rds.yml --extra-vars env=prod
```

### Initialize MIG database

From the created bastion host instance, access the RDS instance using `psql` and
initialize the MIG database from the database schema.

### Deploy and promote application

```
ansible-playbook playbooks/app.yml --extra-vars env=prod
ansible-playbook playbooks/promote-app.yml --extra-vars env=prod
```

## Updating

To update, the rds and app stacks are replaced.

### Snapshot RDS instance

Create a snapshot of the MIG RDS instance.

### Create new RDS stack using snapshot

Note the stack ID should be incremented.

```
ansible-playbook playbooks/rds.yml --extra-vars 'env=prod dbsnapshotid=mysnapshot rds_stack_id=2'
```

After this step, you can log into the bastion host and make any required schema changes
to the new RDS instance, and perform any required maintenance before the database is made
live.

### Deploy new app stack and promote

```
ansible-playbook playbooks/app.yml --extra-vars 'env=prod rds_stack_id=2 app_stack_id=2'
ansible-playbook playbooks/promote-app.yml --extra-vars 'env=prod rds_stack_id=2 app_stack_id=2'
```

At this point the old app and rds stacks can be removed.

### Update API and Scheduler configurations

Once the new RDS and EC2 instances are created, the MIG API and Scheduler will need to have
their configurations updated to point to the new RDS instance.  Get the instance ID from the
AWS console under the RDS service and then edit `/etc/mig/api.cfg` and `/etc/mig/scheduler.cfg`
respectively.
