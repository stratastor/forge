
# Staging Environment Deployment Guide

This guide outlines the steps to deploy, validate, and destroy a staging environment built on AWS using Terraform. It includes pre-installed tools such as Go, Docker, and ZFS for your development and testing needs.

## Table of Contents
1. [Deployment](#deployment)
2. [Validation](#validation)
3. [Destruction](#destruction)
4. [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying, ensure you have:
1. Terraform installed (v1.x or later).
2. AWS credentials with necessary permissions.
3. A key pair created in the specified AWS region for SSH access.
4. The `git` command installed on your local machine.

## Deployment

To deploy the staging environment, follow these steps from the `forge` directory.

1. Move into the `infra` directory.
```bash
cd infra
```

2. Initialize terraform.
```bash
terraform init
```

3. Create a `terraform.tfvars` file in the `infra` directory and configure it as follows. Here's an example.
```bash
aws_access_key = "REDACTED"
aws_secret_key = "REDACTED"
aws_region = "ap-south-1"
aws_vpc_cidr_block="10.0.0.0/16"
aws_subnet_cidr_block = "10.0.1.0/24"
aws_ami = "yourAMI"
aws_availability_zone = "ap-south-1a"
aws_instance_type = "t2.micro"
aws_key_name = "yourKeyName"
```

`aws_ami`: Find the latest Ubuntu AMI ID for your region [here](https://cloud-images.ubuntu.com/locator/).

`aws_key_name`: Specify the name of your key pair created in the AWS Management Console.

Read the `variables.tf` file to understand what each variable is supposed to do

4. Deploy the environment
```bash
terraform apply --auto-approve
```
If your configuration is correct, this should run without any errors
SSH into the EC2 named "Staging Environment" and move on to validating it.

## Validation
A shell script would be running in the background as soon as you SSH into the EC2 that has just been deployed. This will take some time to download all the required tools and packages

1. Check the script's progress
To check if the script has finished running, view the log file:
```bash
sudo cat /var/log/cloud-init-output.log
```
If this is the last line 
```bash
Cloud-init v. 24.3.1-0ubuntu0~24.04.2 finished at <DATE>. Datasource DataSourceEc2Local.  Up 1538.40 seconds
```
The setup is complete and the shell script has finished running. Otherwise please continue to wait for it to finish (It can take upto 30 mins)

To monitor the script progress in real-time, use:
```bash
tail -f /var/log/cloud-init-output.log
```


2. Check the installations of go, docker, and zfs
```bash
go version
docker --version
zfs --version
```
The expected output should be:
```bash
go version go1.23.4 linux/amd64
Docker version 27.5.0, build a187fa5
zfs-2.3.0-rc5
zfs-kmod-2.2.2-0ubuntu9
```


3. Check if zfs has been installed
```bash
cd ~
git clone https://github.com/stratastor/rodent.git
cd rodent/pkg/zfs/dataset/ && sudo go test -v -run TestDatasetOperations
```

This is the successful output
```bash
--- PASS: TestDatasetOperations (2.84s)
    --- PASS: TestDatasetOperations/Filesystems (0.57s)
        --- PASS: TestDatasetOperations/Filesystems/Create (0.12s)
        --- PASS: TestDatasetOperations/Filesystems/Properties (0.05s)
        --- PASS: TestDatasetOperations/Filesystems/Snapshots (0.08s)
        --- PASS: TestDatasetOperations/Filesystems/Clones (0.08s)
        --- PASS: TestDatasetOperations/Filesystems/Inherit (0.02s)
        --- PASS: TestDatasetOperations/Filesystems/Mount (0.13s)
        --- PASS: TestDatasetOperations/Filesystems/Rename (0.05s)
        --- PASS: TestDatasetOperations/Filesystems/Destroy (0.05s)
    --- PASS: TestDatasetOperations/Volumes (0.35s)
        --- PASS: TestDatasetOperations/Volumes/CreateVolume (0.12s)
        --- PASS: TestDatasetOperations/Volumes/CreateSparseVolume (0.05s)
        --- PASS: TestDatasetOperations/Volumes/CreateVolumeWithParent (0.18s)
    --- PASS: TestDatasetOperations/DiffOperations (0.32s)
        --- PASS: TestDatasetOperations/DiffOperations/SnapshotDiff (0.01s)
        --- PASS: TestDatasetOperations/DiffOperations/FileModification (0.07s)
        --- PASS: TestDatasetOperations/DiffOperations/RenameOperation (0.05s)
        --- PASS: TestDatasetOperations/DiffOperations/ErrorCases (0.01s)
            --- PASS: TestDatasetOperations/DiffOperations/ErrorCases/missing_names (0.00s)
            --- PASS: TestDatasetOperations/DiffOperations/ErrorCases/single_name (0.00s)
            --- PASS: TestDatasetOperations/DiffOperations/ErrorCases/non-existent_snapshot (0.01s)
    --- PASS: TestDatasetOperations/ShareOperations (1.16s)
        --- SKIP: TestDatasetOperations/ShareOperations/ShareDataset (0.03s)
        --- PASS: TestDatasetOperations/ShareOperations/ShareAll (0.14s)
        --- PASS: TestDatasetOperations/ShareOperations/UnshareDataset (0.07s)
        --- PASS: TestDatasetOperations/ShareOperations/UnshareAll (0.02s)
        --- PASS: TestDatasetOperations/ShareOperations/ErrorCases (0.00s)
PASS
ok      github.com/stratastor/rodent/pkg/zfs/dataset    2.894s
```

If all the tests are passed, zfs has been installed successfully!

## Destruction
To destroy the staging environment, from the `forge/infra` directory, run 

```bash
terraform destroy --auto-approve
```