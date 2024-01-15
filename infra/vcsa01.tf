################################################################################
# Inventory
################################################################################

resource "vsphere_datacenter" "prod" {
  name = "cai02.nyrvama.com"
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

################################################################################
# Datastores
################################################################################

data "vsphere_datastore" "iscsi01_esxi01" {
  name          = vsphere_vmfs_datastore.iscsi01_esxi01.name
  datacenter_id = vsphere_datacenter.prod.moid
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
