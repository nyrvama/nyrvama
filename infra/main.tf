terraform {
  required_version = "=1.9.2"
  backend "local" {
  }
  required_providers {
    random = {
      version = "=3.6.0"
    }
    vsphere = {
      version = "=2.8.2"
    }
  }
}

provider "vsphere" {
}
