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

  connected   = true
  maintenance = false
  lockdown    = "disabled"
}

################################################################################
# Outputs
################################################################################

output datacenter_id {
  value = vsphere_datacenter.prod.moid
}
