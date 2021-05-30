terraform {
  required_providers {
    docker = {
      source = "terraform-providers/docker"
      version = "~> 2.7.2"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "centos8" {
  name         = "centos:8.3.2011"
  keep_locally = true
}

resource "docker_container" "centos8" {
  image       = docker_image.centos8.latest
  name        = "centos8"
  # restart     = "on-failure"
  memory      = 512
  # start       = true
  # must_run    = true
  command   = [
    "tail",
    "-f",
    "/dev/null"
  ]
}
