variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "terraformvmss"
}
variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "southeastasia"
}
variable "managed_image_resourcegroup_name" {
  description = "The name of resource group, where managed image will be created"
  default = "test-imgrepo-rg"
}
variable "managed_image_name" {
  description = "The name of managed image to be created."
  default = "imgtestwithdatadisk"
}