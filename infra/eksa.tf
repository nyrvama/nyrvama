################################################################################
# Locals
################################################################################

locals {
  eksa_user = "eksa"
  csp_user  = "csp"
}

################################################################################
# OVF Templates
################################################################################

data "vsphere_ovf_vm_template" "eksa_bottlerocket" {
  name  = trimsuffix(reverse(split("/", var.eksa_bottlerocket_ova_url))[0], ".ova")

  resource_pool_id  = vsphere_resource_pool.eksa.id
  host_system_id    = vsphere_host.esxi01.id
  datastore_id      = data.vsphere_datastore.iscsi01_esxi01.id
  folder            = vsphere_folder.eksa_templates.path

  remote_ovf_url            = var.eksa_bottlerocket_ova_url
  allow_unverified_ssl_cert = true

  disk_provisioning = "thin"
  ovf_network_map = {
    "VM Network" : vsphere_distributed_port_group.VM_vcsa01.id
  }
}

################################################################################
# EKSA User
################################################################################

resource "random_password" "eksa_user" {
  length = "12"
}

# resource "null_resource" "eksa_user" {
#   provisioner "local-exec" {
#     command = "echo \"${local.eksa_user}\" > user.yaml && eksctl anywhere exp vsphere setup user -f user.yaml --password ${random_password.eksa_user.result}"
#   }
# }

################################################################################
# CSP User
################################################################################

resource "random_password" "csp_user" {
  length = "12"
}

# resource "null_resource" "csp_user" {
#   provisioner "local-exec" {
#     command = "echo \"${local.csp_user}\" > user.yaml && eksctl anywhere exp vsphere setup user -f user.yaml --password ${random_password.csp_user.result}"
#   }
# }

################################################################################
# Cluster Resources
################################################################################

resource "vsphere_resource_pool" "eksa" {
  name                    = "EKSA ResourcePool"
  parent_resource_pool_id = vsphere_compute_cluster.prod.resource_pool_id
}

resource "vsphere_entity_permissions" "eksa_user_ResourcePool" {
  for_each = toset([vsphere_resource_pool.eksa.id])
  
  entity_id   = each.key
  entity_type = "ResourcePool"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_user.id
    is_group      = false
    propagate     = true
  }
}

resource "vsphere_folder" "eksa" {
  path          = "EKSA"
  type          = "vm"
  datacenter_id = vsphere_datacenter.prod.moid
}

resource "vsphere_entity_permissions" "eksa_VM" {
  for_each = toset([vsphere_folder.eksa.id])
  
  entity_id   = each.key
  entity_type = "Folder"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_admin.id
    is_group      = false
    propagate     = true
  }

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
    role_id       = vsphere_role.cns_vm.id
    is_group      = false
    propagate     = true
  }
}

resource "vsphere_folder" "eksa_templates" {
  path          = "EKSA/Templates"
  type          = "vm"
  datacenter_id = vsphere_datacenter.prod.moid
}

resource "vsphere_entity_permissions" "eksa_VMTemplates" {
  for_each = toset([vsphere_folder.eksa_templates.id])
  
  entity_id   = each.key
  entity_type = "Folder"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_admin.id
    is_group      = false
    propagate     = true
  }
}

################################################################################
# Outputs
################################################################################
