# Under Construction


terraform -chdir=terraform/dev init \
  -backend-config="bucket=$TF_VAR_tf_state_bucket" \
  -backend-config="region=$TF_VAR_tf_state_region" \
  -backend-config="key=$TF_VAR_tf_state_key"