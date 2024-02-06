default: devcheck

fmt:
	@echo "==> Formatting Terraform code with terraform fmt..."
	@terraform fmt -recursive .

fmt-check:
	@echo "==> Checking Terraform code with terraform fmt..."
	@terraform fmt -recursive -check .

tflint:
	@echo "==> Checking Terraform code with tflint..."
	@tflint

trivy:
	@echo "==> Checking Terraform code with trivy..."
	@trivy config ./

devcheck: fmt fmt-check validate tflint trivy

.PHONY: devcheck fmt fmt-check validate tflint trivy