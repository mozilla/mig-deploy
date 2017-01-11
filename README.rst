mig-deploy
==========

Ansible playbooks and associated CloudFormation templates to deploy a MIG
environment into AWS.

A few CloudFormation templates exist which depend on each other, so the
order of playbook execution is important.

See variables in `vars/default.yml`_ for variables that can be changed to
modify playbook execution.

.. _vars/default.yml: vars/default.yml

Playbooks
---------

role
~~~~

Stack creates a new MIG instance IAM role that will be associated with MIG
EC2 instances. The role is assigned read permissions for ``mig/*`` under
``sopss3arn``. When instances are launched they will fetch various environment
specific configuration data from this S3 bucket that is used when the instance
configures itself. The file in S3 should be called ``mig-sec-dev.yml`` for a
development environment, or ``mig-sec-prod.yml`` for a production environment.

See `doc/example-sec-env.yml`_ for an example of what the contents of this
file should be and how it should be encrypted using `sops`_.

.. _doc/example-sec-env.yml: doc/example-sec-env.yml

.. _sops: https://github.com/mozilla/sops

Once the role stack is deployed, ensure the new instance role is assigned permissions
to decrypt data using the KMS ARN used for sops encryption in the account, as
sops will make use of the instance role to decrypt the file stored in S3 to configure
the instance.

base
~~~~

Stack creates the base MIG VPC, associated subnets, and NAT instance.

rds
~~~

Stack creates a Postgres RDS instance which will host the MIG database. When
new stacks are created to replace an old stack, generally a new ``rds``,
and ``app`` stack will be created. We require a new ``rds`` stack as currently
it is not possible to share the same database instance between multiple running
instances of the scheduler. This role supports supplying a database snapshot
identifier ``dbsnapshotid``. You can create a snapshot of a current database instance,
and supply the snapshot name here to import the data into the new RDS instance as
part of an update.

app
~~~

Stack deploys the MIG application, including the API, scheduler, and relays.

