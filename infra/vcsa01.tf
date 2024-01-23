################################################################################
# Inventory
################################################################################

#
#? NOTE: Global permissions
#
# As of time of writing, vSphere doesn't expose a way to set a role for a user
# or group at a "global" level through via its programatic API.
#
# Instead, the suggested workaround from [AWS](https://anywhere.eks.amazonaws.com/docs/getting-started/vsphere/vsphere-preparation/#manually-set-global-permissions-role-in-global-permissions-ui)
# is to implement this configuration manually using the web client.
#
# The following `terraform` block is NOT actually a valid resource, but simply
# serves as breadcrumbs for future reference.
#
# resource "vsphere_entity_permissions" "root" {
#   entity_id   = vsphere_instance.root.id
#   entity_type = ""

#   permissions {
#     user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
#     role_id       = vsphere_role.eksa_global.id
#     is_group      = false
#     propagate     = true
#   }

#   permissions {
#     user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
#     role_id       = data.vsphere_role.read_only.id
#     is_group      = false
#     propagate     = false
#   }
# }

resource "vsphere_datacenter" "prod" {
  name = "cai02.nyrvama.com"
}

resource "vsphere_entity_permissions" "datacenters" {
  for_each = toset([vsphere_datacenter.prod.moid])

  entity_id   = each.key
  entity_type = "Datacenter"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
    role_id       = data.vsphere_role.read_only.id
    is_group      = false
    propagate     = false    
  }
}

resource "vsphere_host" "esxi01" {
  hostname  = var.vsphere_server_esxi01
  username  = var.vsphere_user_esxi01
  password  = var.vsphere_password_esxi01
  
  datacenter  = vsphere_datacenter.prod.moid
  thumbprint  = var.vsphere_thumbprint_esxi01
  license     = var.vsphere_license_key
  
  cluster         = "domain-c1035"
  connected       = true
  maintenance     = false
  lockdown        = "disabled"
}

resource "vsphere_entity_permissions" "hosts" {
  for_each = toset([vsphere_host.esxi01.id])
  
  entity_id   = each.key
  entity_type = "HostSystem"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
    role_id       = data.vsphere_role.read_only.id
    is_group      = false
    propagate     = false
  }
}

# terraform import vsphere_compute_cluster.prod /cai02.nyrvama.com/host/production
resource "vsphere_compute_cluster" "prod" {
  name            = "production"
  datacenter_id   = vsphere_datacenter.prod.moid
  host_system_ids = [vsphere_host.esxi01.id]

  drs_enabled          = true
  drs_automation_level = "fullyAutomated"
  dpm_automation_level = "automated"

  ha_enabled = false
  ha_datastore_apd_response = "restartConservative"
  ha_datastore_pdl_response = "restartAggressive"
}
resource "vsphere_entity_permissions" "cluster" {
  for_each = toset([vsphere_compute_cluster.prod.id])
  
  entity_id   = each.key
  entity_type = "HostSystem"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
    role_id       = data.vsphere_role.read_only.id
    is_group      = false
    propagate     = false
  }
}

################################################################################
# Datastores
################################################################################

data "vsphere_datastore" "iscsi01_esxi01" {
  name          = vsphere_vmfs_datastore.iscsi01_esxi01.name
  datacenter_id = vsphere_datacenter.prod.moid
}

resource "vsphere_entity_permissions" "datastores" {
  for_each = toset([data.vsphere_datastore.iscsi01_esxi01.id])

  entity_id   = each.key
  entity_type = "Datastore"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_user.id
    is_group      = false
    propagate     = true
  }

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.csp_user}"
    role_id       = vsphere_role.cns_datastore.id
    is_group      = false
    propagate     = false
  }
}

################################################################################
# Distributed Switches
################################################################################

resource "vsphere_distributed_virtual_switch" "VM_vcsa01" {
  name          = "VM vdSwitch"
  datacenter_id = vsphere_datacenter.prod.moid

  uplinks         = ["uplink1", "uplink2"]
  active_uplinks  = ["uplink1"]
  standby_uplinks = ["uplink2"]

  host {
    host_system_id = vsphere_host.esxi01.id
    devices        = var.vsphere_nics.virtual_machines
  }

  allow_forged_transmits  = false
  allow_mac_changes       = false
  allow_promiscuous       = false
}

################################################################################
# Distributed Port Groups
################################################################################

resource "vsphere_distributed_port_group" "VM_vcsa01" {
  name                            = "VM dNetwork"
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.VM_vcsa01.id

  vlan_id = 0
}

resource "vsphere_entity_permissions" "eksa_user_dPortGroup" {
  entity_id   = vsphere_distributed_port_group.VM_vcsa01.id
  entity_type = "DistributedVirtualPortgroup"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_user.id
    is_group      = false
    propagate     = true
  }
}

################################################################################
# Virtual NICs
################################################################################

resource "vsphere_vnic" "VM_esxi01" {
  host  = vsphere_host.esxi01.id

  distributed_switch_port = vsphere_distributed_virtual_switch.VM_vcsa01.id
  distributed_port_group  = vsphere_distributed_port_group.VM_vcsa01.id

  ipv4 {
    dhcp = true
  }

  services = ["management", "vmotion", "vsan"]
}

################################################################################
# Outputs
################################################################################

output datacenter_id {
  value = vsphere_datacenter.prod.moid
}
