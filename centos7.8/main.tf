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

resource "docker_image" "centos7" {
  name         = "centos:7.8.2003"
  keep_locally = true
}

resource "docker_container" "centos7" {
  image = docker_image.centos7.latest
  name  = "centos7"
  # restart = "on-failure"
  memory = 512
  start = true
  must_run = true
}
