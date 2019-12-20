output "bootstrap_ignition_source_uri" {
  value = module.openshift_azure_storage_ignition.bootstrap_ignition_source_uri
}

output "master_ignition_source_uri" {
  value = module.openshift_azure_storage_ignition.master_ignition_source_uri
}

output "worker_ignition_source_uri" {
  value = module.openshift_azure_storage_ignition.worker_ignition_source_uri
}