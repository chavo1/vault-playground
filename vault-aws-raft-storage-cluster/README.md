# Create a Vault HA cluster on AWS using Terraform

Learning repo based on the following guide [Vault HA Cluster with Integrated Storage on AWS](https://learn.hashicorp.com/vault/operations/raft-storage-aws).


### Prerequisite

- [AWS account](https://aws.amazon.com/console/)
- [Terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli)

export your AWS credentials:

```
$ export AWS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>"
$ export AWS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>"
```

#### Example `terrafrom.tfvars`
```
# SSH key name to access EC2 instances (should already exist) on the AWS region
key_name = "vault"

# If you want to use a different AWS region
aws_region = "us-east-1"
availability_zones = "us-east-1a"
```

Execute Terraform commands

```
$ terraform init
$ terraform plan
$ terraform apply
```

### The output should be as follow:

```
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.

Outputs:

endpoints = <<EOT

  NOTE: While Terraform's work is done, these instances need time to complete
        their own installation and configuration. Progress is reported within
        the log file `/var/log/tf-user-data.log` and reports 'Complete' when
        the instance is ready.

  vault_1 (13.48.106.218) | internal: (10.0.101.21)
    - Initialized and unsealed.
    - The root token creates a transit key that enables the other Vaults to auto-unseal.
    - Does not join the High-Availability (HA) cluster.

  vault_2 (16.170.155.47) | internal: (10.0.101.22)
    - Initialized and unsealed.
    - The root token and recovery key is stored in /tmp/key.json.
    - K/V-V2 secret engine enabled and secret stored.
    - Leader of HA cluster

    $ ssh -l ubuntu 16.170.155.47 -i chavo.pem

    # Root token:
    $ ssh -l ubuntu 16.170.155.47 -i chavo.pem "cat ~/root_token"
    # Recovery key:
    $ ssh -l ubuntu 16.170.155.47 -i chavo.pem "cat ~/recovery_key"

  vault_3 (16.16.64.79) | internal: (10.0.101.23)
    - Started
    - You will join it to cluster started by vault_2

    $ ssh -l ubuntu 16.16.64.79 -i chavo.pem

  vault_4 (13.51.6.131) | internal: (10.0.101.24)
    - Started
    - You will join it to cluster started by vault_2

    $ ssh -l ubuntu 13.51.6.131 -i chavo.pem


EOT
```

1.  SSH into **vault_2**.

```sh
ssh -l ubuntu 13.56.255.200 -i <path/to/key.pem>
```

2.  Check the current number of servers in the HA Cluster.

```plaintext
$ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft list-peers
Node       Address             State     Voter
----       -------             -----     -----
vault_2    10.0.101.22:8201    leader    true
```

3.  Open a new terminal, SSH into **vault_3**.

```plaintext
$ ssh -l ubuntu 54.183.62.59 -i <path/to/key.pem>
```

4.  Join **vault_3** to the HA cluster started by **vault_2**.

```plaintext
$ vault operator raft join http://vault_2:8200
```

5.  Open a new terminal and SSH into **vault_4**

```plaintext
$ ssh -l ubuntu 13.57.235.28 -i <path/to/key.pem>
```

6.  Join **vault_4** to the HA cluster started by **vault_2**.

```plaintext
$ vault operator raft join http://vault_2:8200
```

7.  Return to the **vault_2** terminal and check the current number of servers in
the HA Cluster.

```plaintext
$ VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token") vault operator raft list-peers

Node       Address             State       Voter
----       -------             -----       -----
vault_2    10.0.101.22:8201    leader      true
vault_3    10.0.101.23:8201    follower    true
vault_4    10.0.101.24:8201    follower    true
```

### Don't forget to destroy the infra

```
$ terraform destroy
```
