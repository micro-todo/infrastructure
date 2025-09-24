locals {
  region = "eu-west-2" // London
  subnets = {
    public = {
      a = {
        cidr_block = "10.0.0.0/22"
        name       = "microtodo_public_subnet_1"
      },
      b = {
        cidr_block = "10.0.4.0/22"
        name       = "microtodo_public_subnet_2"
      },
      c = {
        cidr_block = "10.0.8.0/22"
        name       = "microtodo_public_subnet_3"
      }
    },
    private = {
      a = {
        cidr_block = "10.0.12.0/22"
        name       = "microtodo_private_subnet_1"
      },
      b = {
        cidr_block = "10.0.16.0/22"
        name       = "microtodo_private_subnet_2"
      },
      c = {
        cidr_block = "10.0.20.0/22"
        name       = "microtodo_private_subnet_3"
      }
    }
  }
}
