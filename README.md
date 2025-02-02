# ACME corp Terraform repository
## FastAPI app deployment
The FastAPI app is deployed as a docker container on an ECS cluster.
The ECS cluster is created with terraform, and the FastAPI app is deployed with the ECS service.
The VPC, subnets, security groups, and other resources are also created with terraform.

## Cluster topology
The ECS cluster is created in a VPC with 3 public subnets and 3 private subnets accross 3 availability zones.
ECS services are deployed in the private subnets, and the load balancer is deployed in the public subnets.
The load balancer is exposed to the internet, and the ECS services are only accessible from the load balancer.
Terraform also creates roles for GitHub actions, and a repository in ECR to store the docker images.

## Out of scope:
- auto-scaling
- monitoring
- logging
- naming conventions

## Terraform backend
The terraform backend is stored in an S3 bucket.
This allows to store the terraform state file in a remote location, and to share it with other team members.

## Terraform execution
Before running terraform, you need to set the AWS credentials in the environment variables.
Alternatively, you can use the AWS CLI to configure the credentials.

The local terraform instance must be initialized with the following command:
```bash
terraform init
```

To check the resources that will be created/modified, run the following command:
```bash
terraform plan
```

To create the resources, run the following command:
```bash
terraform apply
```

To destroy the resources, run the following command:
```bash
terraform destroy
```

## Initial deployment
Since the ECS service requires a docker image, and the docker registry is not yet created, the initial deployment will fail.
This is a classic chicken-and-egg problem.
To avoid this, you can comment set the `deploy_services` variable to `false` in the `main.tf` file.
After the initial deployment, the docker image(s) must be pushed to the ECR repository, and the `deploy_services` variable must be set to `true`.
