variable "vsphere_server_esxi01" {
  type = string
}
variable "vsphere_user_esxi01" {
  type = string
}
variable "vsphere_password_esxi01" {
  type = string
}
variable "vsphere_allow_unverified_ssl_esxi01" {
  type = bool
}
variable vsphere_thumbprint_esxi01 {
  type = string
}

variable "vsphere_license_key" {
  type = string
}

variable "vsphere_disks_physical_regex_esxi01" {
  type = string
}

variable "vsphere_disks_iscsi_regex_esxi01" {
  type = string
}

variable "vsphere_nics" {
  type = map(list(string))
  default = {
    management = ["vmnic0"]
    vCenter = ["vmnic1"]
    virtual_machines = ["vmnic2", "vmnic3"]
    storage = ["vmnic4"]
  }
}
