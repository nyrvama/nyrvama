variable "vsphere_domain" {
  type = string
}
variable "vsphere_server" {
  type = string
}

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

variable "eksa_version" {
  type = string
  default = "v0.18.0"
}
variable "eksa_kubernetes_version" {
  type = string
  default = "v1.28"
}
variable "eksa_bottlerocket_ova_url" {
  type = string
  default = "https://anywhere-assets.eks.amazonaws.com/releases/bundles/56/artifacts/ova/1-28/bottlerocket-v1.28.4-eks-d-1-28-12-eks-a-56-amd64.ova"
}
