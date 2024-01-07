################################################################################
# Provider
################################################################################

provider "vsphere" {
  alias = "esxi01"

  vsphere_server        = var.vsphere_server_esxi01
  user                  = var.vsphere_user_esxi01
  password              = var.vsphere_password_esxi01
  allow_unverified_ssl  = var.vsphere_allow_unverified_ssl_esxi01
}

################################################################################
# Host information
################################################################################

data "vsphere_datacenter" "esxi01" {
  provider = vsphere.esxi01
}

data "vsphere_host" "esxi01" {
  provider = vsphere.esxi01

  datacenter_id = data.vsphere_datacenter.esxi01.id
}

data "vsphere_resource_pool" "esxi01" {
  provider = vsphere.esxi01

}

################################################################################
# License
################################################################################

resource "vsphere_license" "esxi01" {
  provider = vsphere.esxi01

  license_key = var.vsphere_license_key
}

################################################################################
# Disks
################################################################################

data "vsphere_vmfs_disks" "available_esxi01" {
  provider = vsphere.esxi01

  host_system_id  = data.vsphere_host.esxi01.id
  rescan          = false
}

data "vsphere_vmfs_disks" "physical_esxi01" {
  provider = vsphere.esxi01

  host_system_id  = data.vsphere_host.esxi01.id
  rescan          = false
  filter          = var.vsphere_disks_physical_regex_esxi01
}

data "vsphere_vmfs_disks" "iscsi_esxi01" {
  provider = vsphere.esxi01

  host_system_id  = data.vsphere_host.esxi01.id
  rescan          = false
  filter          = var.vsphere_disks_iscsi_regex_esxi01
}

################################################################################
# Datastores
################################################################################

data "vsphere_datastore" "default_esxi01" {
  provider = vsphere.esxi01

  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.esxi01.id
}

resource "vsphere_vmfs_datastore" "iscsi01_esxi01" {
  provider = vsphere.esxi01

  name            = "datastore_iscsi01"
  host_system_id  = data.vsphere_host.esxi01.id
  disks           = data.vsphere_vmfs_disks.iscsi_esxi01.disks
}

################################################################################
# Virtual Switches
################################################################################

# terraform import vsphere_host_virtual_switch.vsw0_esxi01 tf-HostVirtualSwitch:ha-host:vSwitch0
resource "vsphere_host_virtual_switch" "vsw0_esxi01" {
  provider = vsphere.esxi01

  name           = "vSwitch0"
  host_system_id = data.vsphere_host.esxi01.id

  network_adapters  = var.vsphere_nics.management
  active_nics       = var.vsphere_nics.management

  allow_forged_transmits  = false
  allow_mac_changes       = false
}

resource "vsphere_host_virtual_switch" "vCenter_esxi01" {
  provider = vsphere.esxi01

  name           = "vCenter"
  host_system_id = data.vsphere_host.esxi01.id

  network_adapters  = var.vsphere_nics.vCenter
  active_nics       = var.vsphere_nics.vCenter

  allow_forged_transmits  = false
  allow_mac_changes       = false
}

resource "vsphere_host_virtual_switch" "storage_esxi01" {
  provider = vsphere.esxi01

  name           = "Storage vSwitch"
  host_system_id = data.vsphere_host.esxi01.id

  network_adapters  = var.vsphere_nics.storage
  active_nics       = var.vsphere_nics.storage

  allow_forged_transmits  = false
  allow_mac_changes       = false
}

################################################################################
# Port Groups
################################################################################

# terraform import vsphere_host_port_group.management_esxi01 "tf-HostPortGroup:ha-host:Management Network"
resource "vsphere_host_port_group" "management_esxi01" {
  provider = vsphere.esxi01

  name                = "Management Network"
  host_system_id      = data.vsphere_host.esxi01.id
  virtual_switch_name = vsphere_host_virtual_switch.vsw0_esxi01.name
  vlan_id             = 0

  active_nics     = vsphere_host_virtual_switch.vsw0_esxi01.active_nics
}

resource "vsphere_host_port_group" "vCenter_esxi01" {
  provider = vsphere.esxi01

  name                = "vCenter Network"
  host_system_id      = data.vsphere_host.esxi01.id
  virtual_switch_name = vsphere_host_virtual_switch.vCenter_esxi01.name
  vlan_id             = 0

  active_nics     = vsphere_host_virtual_switch.vCenter_esxi01.active_nics
}

resource "vsphere_host_port_group" "storage_esxi01" {
  provider = vsphere.esxi01

  name                = "Storage Network"
  host_system_id      = data.vsphere_host.esxi01.id
  virtual_switch_name = vsphere_host_virtual_switch.storage_esxi01.name
  vlan_id             = 0

  active_nics     = vsphere_host_virtual_switch.storage_esxi01.active_nics
}

################################################################################
# Virtual NICs
################################################################################

resource "vsphere_vnic" "storage_esxi01" {
  provider = vsphere.esxi01

  host      = data.vsphere_host.esxi01.id
  portgroup = vsphere_host_port_group.storage_esxi01.name

  ipv4 {
    ip      = "10.20.31.20"
    netmask = "255.255.255.0"
    gw      = "10.20.31.1"
  }

  services = ["vmotion", "vsan"]
}

################################################################################
# Outputs
################################################################################

output vsphere_vmfs_disks_available_esxi01 {
  value = data.vsphere_vmfs_disks.available_esxi01.disks
}

output vsphere_vmfs_disks_physical_esxi01 {
  value = data.vsphere_vmfs_disks.physical_esxi01.disks
}

output vsphere_vmfs_disks_iscsi_esxi01 {
  value = data.vsphere_vmfs_disks.iscsi_esxi01.disks
}
