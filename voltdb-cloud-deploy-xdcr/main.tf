provider "alicloud" {
    #Replace the access keys with yours.
	access_key = ""
	secret_key = ""
	region = "ap-northeast-1"
}

variable "node_count" {
  default = "2"
}

variable "node_name_prefix" {
  description = "Prefix to use when naming cluster members"
  default = "test-node-"
}

variable "node2_name_prefix" {
  description = "Prefix to use when naming cluster members"
  default = "cluster2-node-"
}

variable "password" {
  type = "string"
  default = "Test1234!"
}

variable "availabe_zone" {
  type = "string"
  default = "ap-northeast-1a"
}

data "alicloud_instance_types" "4c16g" {
  cpu_core_count = 8
  memory_size = 8
}

resource "alicloud_vpc" "vpc" {
  name       = "tf_test_foo"
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "172.16.0.0/21"
  availability_zone = "${var.availabe_zone}"
}


resource "alicloud_security_group" "default" {
  name = "default"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = "${alicloud_security_group.default.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "test-ins" {
  count = "${var.node_count}"
  # cn-beijing
  availability_zone = "${var.availabe_zone}"
  security_groups = ["${alicloud_security_group.default.*.id}"]

  # series III
  instance_type        = "${data.alicloud_instance_types.4c16g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  image_id             = "ubuntu_18_04_64_20G_alibase_20190223.vhd"
  instance_name        = "${var.node_name_prefix}-${count.index}"
  host_name        = "${var.node_name_prefix}${count.index}"
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  internet_max_bandwidth_out = 5
  password = "${var.password}"

}

resource "null_resource" "configure-ins-ips" {
  count = "${var.node_count}"

  provisioner "file" {
        source = "scripts/initialization_env.sh"
        destination = "~/initialization_env.sh"

        connection {
          type     = "ssh"
          user     = "root"
          host = "${element(alicloud_instance.test-ins.*.public_ip, count.index)}"
          password = "${var.password}"
      }
    }

    provisioner "remote-exec" {
        inline = [
            # Adds all cluster members' IP addresses to /etc/hosts (on each member)
            "sudo echo '${join("\n", formatlist("%v", alicloud_instance.test-ins.*.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# Cluster members:\" }; { print $0 \" ${var.node_name_prefix}\" NR-1 }' | sudo tee -a /etc/hosts > /dev/null",
            "sudo echo '${join("\n", formatlist("%v", alicloud_instance.cluster2.*.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# Cluster members:\" }; { print $0 \" ${var.node2_name_prefix}\" NR-1 }' | sudo tee -a /etc/hosts > /dev/null",
            "sudo chmod +x ~/initialization_env.sh",
            "sudo ~/initialization_env.sh 1 \"${join(",", formatlist("%v", alicloud_instance.cluster2.*.host_name))}\"",
            "/opt/voltdb/bin/voltdb start --host=${join(",", formatlist("%v", alicloud_instance.test-ins.*.host_name))} -B"

        ]
        connection {
          type     = "ssh"
          user     = "root"
          host = "${element(alicloud_instance.test-ins.*.public_ip, count.index)}"
          password = "${var.password}"
      }
    }
}

resource "alicloud_instance" "cluster2" {
  count = "${var.node_count}"
  # cn-beijing
  availability_zone = "${var.availabe_zone}"
  security_groups = ["${alicloud_security_group.default.*.id}"]

  # series III
  instance_type        = "${data.alicloud_instance_types.4c16g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  image_id             = "ubuntu_18_04_64_20G_alibase_20190223.vhd"
  instance_name        = "${var.node2_name_prefix}-${count.index}"
  host_name        = "${var.node2_name_prefix}${count.index}"
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  internet_max_bandwidth_out = 5
  password = "${var.password}"

}

resource "null_resource" "configure-ins2-ips" {
  count = "${var.node_count}"

  provisioner "file" {
        source = "scripts/initialization_env.sh"
        destination = "~/initialization_env.sh"

        connection {
          type     = "ssh"
          user     = "root"
          host = "${element(alicloud_instance.cluster2.*.public_ip, count.index)}"
          password = "${var.password}"
      }
    }

    provisioner "remote-exec" {
        inline = [
            # Adds all cluster members' IP addresses to /etc/hosts (on each member)
            "sudo echo '${join("\n", formatlist("%v", alicloud_instance.test-ins.*.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# Cluster members:\" }; { print $0 \" ${var.node_name_prefix}\" NR-1 }' | sudo tee -a /etc/hosts > /dev/null",
            "sudo echo '${join("\n", formatlist("%v", alicloud_instance.cluster2.*.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# Cluster members:\" }; { print $0 \" ${var.node2_name_prefix}\" NR-1 }' | sudo tee -a /etc/hosts > /dev/null",
            "sudo chmod +x ~/initialization_env.sh",
            "sudo ~/initialization_env.sh 2 \"${join(",", formatlist("%v", alicloud_instance.test-ins.*.host_name))}\"",
            "/opt/voltdb/bin/voltdb start --host=${join(",", formatlist("%v", alicloud_instance.cluster2.*.host_name))} -B"

        ]
        connection {
          type     = "ssh"
          user     = "root"
          host = "${element(alicloud_instance.cluster2.*.public_ip, count.index)}"
          password = "${var.password}"
      }
    }
}
