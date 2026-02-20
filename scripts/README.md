# Scripts

## import-existing-resources.sh

Use when Terraform fails with "already exists" because resources were created outside the current state (e.g. previous run, different state backend, or manual creation).

**Before running:** Ensure `project_name` matches the names in AWS. Your errors showed `app-prod-*`, so use `app-prod`:

```bash
cd /path/to/aws_infra
terraform init
export PROJECT_NAME=app-prod
bash scripts/import-existing-resources.sh
```

Then run `terraform plan` (with the same `project_name`, e.g. via `terraform.tfvars` or `-var="project_name=app-prod"`). If you use `terraform.tfvars` with a different name (e.g. `task-prod`), either:

- Use `app-prod` in tfvars so Terraform manages the existing resources, or  
- Run the import script with `PROJECT_NAME=task-prod` only if your existing resources are actually named `task-prod-*`.

**Note:** The script skips imports that fail (e.g. resource already in state). Run `terraform plan` after to see if anything else needs importing.
