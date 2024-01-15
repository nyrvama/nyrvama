################################################################################
# Locals
################################################################################

locals {
  #
  # vSphere user for EKSA Anywhere
  #
  # For reference, check https://anywhere.eks.amazonaws.com/docs/getting-started/vsphere/vsphere-preparation/
  #
 
  # eksa_user = yamlencode({
  #   apiVersion = "eks-anywhere.amazon.com/v1"
  #   kind = "vSphereUser"
  #   spec = {
  #     username = "eksa"   # optional, default eksa
  #     group = "EKSAUsers"   # optional, default EKSAUsers
  #     globalRole = "EKSAGlobalRole"   # optional, default EKSAGlobalRole
  #     userRole = "EKSAUserRole"   # optional, default EKSAUserRole
  #     adminRole = "EKSACloudAdminRole"    # optional, default EKSACloudAdminRole
  #     datacenter = vsphere_datacenter.prod.name
  #     vSphereDomain = var.vsphere_domain    # this should be the domain used when you login, e.g. YourUsername@vsphere.local
  #     connection = {
  #       server = var.vsphere_server
  #       insecure = true
  #     }
  #     objects = {
  #       networks = [
  #         "/${vsphere_datacenter.prod.name}/network/${vsphere_distributed_port_group.VM_vcsa01.name}",
  #       ]
  #       datastores = [
  #         "/${vsphere_datacenter.prod.name}/datastore/${vsphere_vmfs_datastore.iscsi01_esxi01.name}",
  #       ]
  #       resourcePools = [
  #         "/${vsphere_datacenter.prod.name}/host/${vsphere_compute_cluster.prod.name}/Resources/${vsphere_resource_pool.eksa.name}",
  #       ]
  #       folders = [
  #         "/${vsphere_datacenter.prod.name}/vm/${vsphere_folder.eksa.path}",
  #       ]
  #       templates = [
  #         "/${vsphere_datacenter.prod.name}/vm/${vsphere_folder.eksa_templates.path}",
  #       ]
  #     }
  #   }
  # })
  eksa_user = "eksa"
}

################################################################################
# Meta Resources
################################################################################

resource "vsphere_resource_pool" "eksa" {
  name                    = "EKSA ResourcePool"
  parent_resource_pool_id = vsphere_compute_cluster.prod.resource_pool_id
}

resource "vsphere_folder" "eksa" {
  path          = "EKSA"
  type          = "vm"
  datacenter_id = vsphere_datacenter.prod.moid
}

resource "vsphere_folder" "eksa_templates" {
  path          = "EKSA/Templates"
  type          = "vm"
  datacenter_id = vsphere_datacenter.prod.moid
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

resource "vsphere_role" "eksa_global" {
  name = "EKSAGlobalRole"
  role_privileges = [
    "ContentLibrary.AddLibraryItem",
    "ContentLibrary.CheckInTemplate",
    "ContentLibrary.CheckOutTemplate",
    "ContentLibrary.CreateLocalLibrary",
    "ContentLibrary.UpdateSession",
    "InventoryService.Tagging.AttachTag",
    "InventoryService.Tagging.CreateCategory",
    "InventoryService.Tagging.CreateTag",
    "InventoryService.Tagging.DeleteCategory",
    "InventoryService.Tagging.DeleteTag",
    "InventoryService.Tagging.EditCategory",
    "InventoryService.Tagging.EditTag",
    "InventoryService.Tagging.ModifyUsedByForCategory",
    "InventoryService.Tagging.ModifyUsedByForTag",
    "InventoryService.Tagging.ObjectAttachable",
    "Sessions.ValidateSession",
  ]
}

resource "vsphere_role" "eksa_user" {
  name = "EKSAUserRole"
  role_privileges = [
    "ContentLibrary.AddLibraryItem",
    "ContentLibrary.CheckInTemplate",
    "ContentLibrary.CheckOutTemplate",
    "ContentLibrary.CreateLocalLibrary",
    "Datastore.AllocateSpace",
    "Datastore.Browse",
    "Datastore.FileManagement",
    "Folder.Create",
    "InventoryService.Tagging.AttachTag",
    "InventoryService.Tagging.CreateCategory",
    "InventoryService.Tagging.CreateTag",
    "InventoryService.Tagging.DeleteCategory",
    "InventoryService.Tagging.DeleteTag",
    "InventoryService.Tagging.EditCategory",
    "InventoryService.Tagging.EditTag",
    "InventoryService.Tagging.ModifyUsedByForCategory",
    "InventoryService.Tagging.ModifyUsedByForTag",
    "InventoryService.Tagging.ObjectAttachable",
    "Network.Assign",
    "Resource.AssignVMToPool",
    "ScheduledTask.Create",
    "ScheduledTask.Delete",
    "ScheduledTask.Edit",
    "ScheduledTask.Run",
    "StorageProfile.View",
    "StorageViews.View",
    "VApp.Import",
    "VirtualMachine.Config.AddExistingDisk",
    "VirtualMachine.Config.AddNewDisk",
    "VirtualMachine.Config.AddRemoveDevice",
    "VirtualMachine.Config.AdvancedConfig",
    "VirtualMachine.Config.CPUCount",
    "VirtualMachine.Config.DiskExtend",
    "VirtualMachine.Config.EditDevice",
    "VirtualMachine.Config.Memory",
    "VirtualMachine.Config.RawDevice",
    "VirtualMachine.Config.RemoveDisk",
    "VirtualMachine.Config.Settings",
    "VirtualMachine.Interact.PowerOff",
    "VirtualMachine.Interact.PowerOn",
    "VirtualMachine.Inventory.Create",
    "VirtualMachine.Inventory.CreateFromExisting",
    "VirtualMachine.Inventory.Delete",
    "VirtualMachine.Provisioning.Clone",
    "VirtualMachine.Provisioning.CloneTemplate",
    "VirtualMachine.Provisioning.CreateTemplateFromVM",
    "VirtualMachine.Provisioning.Customize",
    "VirtualMachine.Provisioning.DeployTemplate",
    "VirtualMachine.Provisioning.MarkAsTemplate",
    "VirtualMachine.Provisioning.ReadCustSpecs",
    "VirtualMachine.State.CreateSnapshot",
    "VirtualMachine.State.RemoveSnapshot",
    "VirtualMachine.State.RevertToSnapshot",
  ]
}

resource "vsphere_role" "eksa_admin" {
  name = "EKSACloudAdminRole"
  role_privileges = [
    "Alarm.Acknowledge",
    "Alarm.Create",
    "Alarm.Delete",
    "Alarm.DisableActions",
    "Alarm.Edit",
    "Alarm.SetStatus",
    "Authorization.ModifyPermissions",
    "Authorization.ModifyRoles",
    "CertificateManagement.Manage",
    "Cns.Searchable",
    "ComputePolicy.Manage",
    "ContentLibrary.AddCertToTrustStore",
    "ContentLibrary.AddLibraryItem",
    "ContentLibrary.CheckInTemplate",
    "ContentLibrary.CheckOutTemplate",
    "ContentLibrary.CreateLocalLibrary",
    "ContentLibrary.CreateSubscribedLibrary",
    "ContentLibrary.DeleteCertFromTrustStore",
    "ContentLibrary.DeleteLibraryItem",
    "ContentLibrary.DeleteLocalLibrary",
    "ContentLibrary.DeleteSubscribedLibrary",
    "ContentLibrary.DownloadSession",
    "ContentLibrary.EvictLibraryItem",
    "ContentLibrary.EvictSubscribedLibrary",
    "ContentLibrary.GetConfiguration",
    "ContentLibrary.ImportStorage",
    "ContentLibrary.ProbeSubscription",
    "ContentLibrary.ReadStorage",
    "ContentLibrary.SyncLibrary",
    "ContentLibrary.SyncLibraryItem",
    "ContentLibrary.TypeIntrospection",
    "ContentLibrary.UpdateConfiguration",
    "ContentLibrary.UpdateLibrary",
    "ContentLibrary.UpdateLibraryItem",
    "ContentLibrary.UpdateLocalLibrary",
    "ContentLibrary.UpdateSession",
    "ContentLibrary.UpdateSubscribedLibrary",
    "Datastore.AllocateSpace",
    "Datastore.Browse",
    "Datastore.Config",
    "Datastore.DeleteFile",
    "Datastore.FileManagement",
    "Datastore.UpdateVirtualMachineFiles",
    "Datastore.UpdateVirtualMachineMetadata",
    "Extension.Register",
    "Extension.Unregister",
    "Extension.Update",
    "Folder.Create",
    "Folder.Delete",
    "Folder.Move",
    "Folder.Rename",
    "Global.CancelTask",
    "Global.GlobalTag",
    "Global.Health",
    "Global.LogEvent",
    "Global.ManageCustomFields",
    "Global.ServiceManagers",
    "Global.SetCustomField",
    "Global.SystemTag",
    "HLM.Manage",
    "Host.Hbr.HbrManagement",
    "InventoryService.Tagging.AttachTag",
    "InventoryService.Tagging.CreateCategory",
    "InventoryService.Tagging.CreateTag",
    "InventoryService.Tagging.DeleteCategory",
    "InventoryService.Tagging.DeleteTag",
    "InventoryService.Tagging.EditCategory",
    "InventoryService.Tagging.EditTag",
    "InventoryService.Tagging.ModifyUsedByForCategory",
    "InventoryService.Tagging.ModifyUsedByForTag",
    "InventoryService.Tagging.ObjectAttachable",
    "Namespaces.Configure",
    "Namespaces.SelfServiceManage",
    "Network.Assign",
    "Resource.ApplyRecommendation",
    "Resource.AssignVAppToPool",
    "Resource.AssignVMToPool",
    "Resource.ColdMigrate",
    "Resource.CreatePool",
    "Resource.DeletePool",
    "Resource.EditPool",
    "Resource.HotMigrate",
    "Resource.MovePool",
    "Resource.QueryVMotion",
    "Resource.RenamePool",
    "ScheduledTask.Create",
    "ScheduledTask.Delete",
    "ScheduledTask.Edit",
    "ScheduledTask.Run",
    "Sessions.GlobalMessage",
    "Sessions.ValidateSession",
    "StorageProfile.Update",
    "StorageProfile.View",
    "StorageViews.View",
    "Trust.Manage",
    "VApp.ApplicationConfig",
    "VApp.AssignResourcePool",
    "VApp.AssignVApp",
    "VApp.AssignVM",
    "VApp.Clone",
    "VApp.Create",
    "VApp.Delete",
    "VApp.Export",
    "VApp.ExtractOvfEnvironment",
    "VApp.Import",
    "VApp.InstanceConfig",
    "VApp.ManagedByConfig",
    "VApp.Move",
    "VApp.PowerOff",
    "VApp.PowerOn",
    "VApp.Rename",
    "VApp.ResourceConfig",
    "VApp.Suspend",
    "VApp.Unregister",
    "VirtualMachine.Config.AddExistingDisk",
    "VirtualMachine.Config.AddNewDisk",
    "VirtualMachine.Config.AddRemoveDevice",
    "VirtualMachine.Config.AdvancedConfig",
    "VirtualMachine.Config.Annotation",
    "VirtualMachine.Config.CPUCount",
    "VirtualMachine.Config.ChangeTracking",
    "VirtualMachine.Config.DiskExtend",
    "VirtualMachine.Config.DiskLease",
    "VirtualMachine.Config.EditDevice",
    "VirtualMachine.Config.HostUSBDevice",
    "VirtualMachine.Config.ManagedBy",
    "VirtualMachine.Config.Memory",
    "VirtualMachine.Config.MksControl",
    "VirtualMachine.Config.QueryFTCompatibility",
    "VirtualMachine.Config.QueryUnownedFiles",
    "VirtualMachine.Config.RawDevice",
    "VirtualMachine.Config.ReloadFromPath",
    "VirtualMachine.Config.RemoveDisk",
    "VirtualMachine.Config.Rename",
    "VirtualMachine.Config.ResetGuestInfo",
    "VirtualMachine.Config.Resource",
    "VirtualMachine.Config.Settings",
    "VirtualMachine.Config.SwapPlacement",
    "VirtualMachine.Config.UpgradeVirtualHardware",
    "VirtualMachine.GuestOperations.Execute",
    "VirtualMachine.GuestOperations.Modify",
    "VirtualMachine.GuestOperations.ModifyAliases",
    "VirtualMachine.GuestOperations.Query",
    "VirtualMachine.GuestOperations.QueryAliases",
    "VirtualMachine.Hbr.ConfigureReplication",
    "VirtualMachine.Hbr.MonitorReplication",
    "VirtualMachine.Hbr.ReplicaManagement",
    "VirtualMachine.Interact.AnswerQuestion",
    "VirtualMachine.Interact.Backup",
    "VirtualMachine.Interact.ConsoleInteract",
    "VirtualMachine.Interact.CreateScreenshot",
    "VirtualMachine.Interact.DefragmentAllDisks",
    "VirtualMachine.Interact.DeviceConnection",
    "VirtualMachine.Interact.DnD",
    "VirtualMachine.Interact.GuestControl",
    "VirtualMachine.Interact.Pause",
    "VirtualMachine.Interact.PowerOff",
    "VirtualMachine.Interact.PowerOn",
    "VirtualMachine.Interact.PutUsbScanCodes",
    "VirtualMachine.Interact.Reset",
    "VirtualMachine.Interact.SESparseMaintenance",
    "VirtualMachine.Interact.SetCDMedia",
    "VirtualMachine.Interact.SetFloppyMedia",
    "VirtualMachine.Interact.Suspend",
    "VirtualMachine.Interact.ToolsInstall",
    "VirtualMachine.Inventory.Create",
    "VirtualMachine.Inventory.CreateFromExisting",
    "VirtualMachine.Inventory.Delete",
    "VirtualMachine.Inventory.Move",
    "VirtualMachine.Inventory.Register",
    "VirtualMachine.Inventory.Unregister",
    "VirtualMachine.Namespace.Event",
    "VirtualMachine.Namespace.EventNotify",
    "VirtualMachine.Namespace.Management",
    "VirtualMachine.Namespace.ModifyContent",
    "VirtualMachine.Namespace.Query",
    "VirtualMachine.Namespace.ReadContent",
    "VirtualMachine.Provisioning.Clone",
    "VirtualMachine.Provisioning.CloneTemplate",
    "VirtualMachine.Provisioning.CreateTemplateFromVM",
    "VirtualMachine.Provisioning.Customize",
    "VirtualMachine.Provisioning.DeployTemplate",
    "VirtualMachine.Provisioning.DiskRandomAccess",
    "VirtualMachine.Provisioning.DiskRandomRead",
    "VirtualMachine.Provisioning.FileRandomAccess",
    "VirtualMachine.Provisioning.GetVmFiles",
    "VirtualMachine.Provisioning.MarkAsTemplate",
    "VirtualMachine.Provisioning.MarkAsVM",
    "VirtualMachine.Provisioning.ModifyCustSpecs",
    "VirtualMachine.Provisioning.PromoteDisks",
    "VirtualMachine.Provisioning.PutVmFiles",
    "VirtualMachine.Provisioning.ReadCustSpecs",
    "VirtualMachine.State.CreateSnapshot",
    "VirtualMachine.State.RemoveSnapshot",
    "VirtualMachine.State.RenameSnapshot",
    "VirtualMachine.State.RevertToSnapshot",
    "VirtualMachineClasses.Manage",
    "Vsan.Cluster.ShallowRekey",
    "vService.CreateDependency",
    "vService.DestroyDependency",
    "vService.ReconfigureDependency",
    "vService.UpdateDependency",
    "vSphereDataProtection.Protection",
    "vSphereDataProtection.Recovery"
  ]
}

resource "random_password" "eksa_user" {
  length = "12"
}

# resource "null_resource" "eksa_user" {
#   provisioner "local-exec" {
#     command = "echo \"${local.eksa_user}\" > user.yaml && eksctl anywhere exp vsphere setup user -f user.yaml --password ${random_password.eksa_user.result}"
#   }
# }

resource "vsphere_entity_permissions" "eksa_admin_VM" {
  entity_id   = vsphere_folder.eksa.id
  entity_type = "Folder"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_admin.id
    is_group      = false
    propagate     = true
  }
}

resource "vsphere_entity_permissions" "eksa_admin_VMTemplates" {
  entity_id   = vsphere_folder.eksa_templates.id
  entity_type = "Folder"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_admin.id
    is_group      = false
    propagate     = true
  }
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

resource "vsphere_entity_permissions" "eksa_user_Datastore" {
  entity_id   = data.vsphere_datastore.iscsi01_esxi01.id
  entity_type = "Datastore"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_user.id
    is_group      = false
    propagate     = true
  }
}

resource "vsphere_entity_permissions" "eksa_user_ResourcePool" {
  entity_id   = vsphere_resource_pool.eksa.id
  entity_type = "ResourcePool"

  permissions {
    user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
    role_id       = vsphere_role.eksa_user.id
    is_group      = false
    propagate     = true
  }
}

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
# resource "vsphere_entity_permissions" "eksa_global_Root" {
#   entity_id   = vsphere_instance.root.id
#   entity_type = ""

#   permissions {
#     user_or_group = "${upper(var.vsphere_domain)}\\${local.eksa_user}"
#     role_id       = vsphere_role.eksa_global.id
#     is_group      = false
#     propagate     = true
#   }
# }

################################################################################
# Outputs
################################################################################

output "eks_user" {
  value = local.eksa_user
}
