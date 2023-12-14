packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

// Add info of service prinicple. 
// Do not commit this file to git if you are using a real service prinicple.
variable client_id {
  type = string
  default = "CLIENT_ID"
}
variable client_secret {
  type = string
  default = "CLIENT_SECRET"
}

variable subscription_id {
  type = string
  default = "SUBSCRIPTION_ID"
}

variable tenant_id {
  type = string
  default = "TENANT_ID"
}

variable location {
  default = "LOCATION"
}

variable "image_resource_group_name" {
  description = "Name of the resource group in which the Packer image will be created"
  default     = "test-imgrepo-rg"
}

source "azure-arm" "builder" {
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  image_offer                       = "0001-com-ubuntu-server-jammy"
  image_publisher                   = "canonical"
  image_sku                         = "22_04-lts"
  location                          = var.location
  managed_image_name                = "imgtestwithdatadisk"
  managed_image_resource_group_name = var.image_resource_group_name
  os_type                           = "Linux"
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = "Standard_DS2_v2"
  azure_tags                        = {
    "dept" : "Engineering",
    "task" : "Image deployment",
  }
}

build {
  sources = ["source.azure-arm.builder"]
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get -y install nginx",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync",
    ]
  }
}