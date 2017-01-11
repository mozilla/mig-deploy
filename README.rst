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

base
~~~~

rds
~~~

app
~~~

