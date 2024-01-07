terraform {
  required_version = "=1.6.6"
  backend "local" {
  }
  required_providers {
    vsphere = {
      version = "=2.6.1"
    }
  }
}

provider "vsphere" {
}
