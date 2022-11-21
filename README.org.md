# Infrastructure for Blendnet

## Prereqs

Install `az-cli`, `terraform` cli.

## Run

## Provision core infra

1. Run `./scripts/init.sh --env dev|prod|stage --region centralindia` to create a storage account in the resource group. (Defaults are env: stage and region: centralindia)
2. Run ./scripts/aks-ssh-create.sh --env dev|prod|stage --region centralindia to create ssh key required for aks.
3. Initialize backend for a building terraform's state

```
cd core/
export ENVIRONMENT=<env_name>
export ARM_ACCESS_KEY=<key from the init script>
export TF_CLI_ARGS_init="-backend-config='resource_group_name=blendnet-$ENVIRONMENT'"
export TF_CLI_ARGS_init="$TF_CLI_ARGS_init -backend-config='storage_account_name=tfstatefor$ENVIRONMENT' -backend-config='container_name=tfstate' -backend-config='key=terraform.tfstate'"

rm -rf .terraform
terraform init

terraform plan -var="environment=$ENVIRONMENT"
terraform apply -var="environment=$ENVIRONMENT"
```

## Provision analytics infra

1. Run `./scripts/init.sh --env dev|prod|stage --region centralindia` to create a storage account in the resource group. (Defaults are env: stage and region: centralindia).
2. Initialize backend for a building terraform's state.

```
cd analytics/
export ENVIRONMENT=<env_name>
export ARM_ACCESS_KEY=<key from the init script>
export TF_CLI_ARGS_init="-backend-config='resource_group_name=nearme-$ENVIRONMENT'"
export TF_CLI_ARGS_init="$TF_CLI_ARGS_init -backend-config='storage_account_name=tfstatefor$ENVIRONMENT' -backend-config='container_name=tfstate' -backend-config='key=terraform.tfstate'"

rm -rf .terraform
terraform init

terraform plan -var="environment=$ENVIRONMENT"
terraform apply -var="environment=$ENVIRONMENT"
```
