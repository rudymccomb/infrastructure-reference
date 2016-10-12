module "config-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-qa-config"
}

module "cloudinit-bucket" {
  source = "github.com/stakater/blueprint-storage-aws.git//modules/s3"
  name = "${var.stack_name}-qa-cloudinit"
}