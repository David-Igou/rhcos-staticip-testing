#Networking

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true
}


resource "aws_subnet" "subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${var.vpc_subnet}"
}


resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Routing

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  # Default route through Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rt.id}"
}


#Security Group

resource "aws_security_group" "sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name   = "sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#EC2

resource "aws_instance" "my_node" {
  ami                         = "${var.server_image_id}"
  instance_type               = "${var.server_instance_type}"
  subnet_id                   = "${aws_subnet.subnet.id}"
  associate_public_ip_address = true # Instances have public, dynamic IP
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  user_data                   = "${file("${path.module}/ignition.ign")}"
}


##EC2
#
#resource "aws_instance" "k3os_master" {
#  ami                         = "${var.server_image_id}"
#  instance_type               = "${var.server_instance_type}"
#  iam_instance_profile        = "${aws_iam_instance_profile.k3os_iamp.id}"
#  subnet_id                   = "${aws_subnet.k3os_subnet.id}"
#  associate_public_ip_address = true # Instances have public, dynamic IP
#  vpc_security_group_ids      = ["${aws_security_group.k3os_sg.id}", "${aws_security_group.k3os_api.id}"]
#  key_name                    = "${var.keypair_name}"
#  user_data                   = "${templatefile("${path.module}/files/config_server.sh", { ssh_keys = var.ssh_keys, data_sources = var.data_sources, kernel_modules = var.kernel_modules, sysctls = var.sysctls, dns_nameservers = var.dns_nameservers, ntp_servers = var.ntp_servers, k3s_cluster_secret = var.k3s_cluster_secret, k3s_args = var.k3s_args })}"
#  tags = {
#    Name                            = "k3os_master",
#    "kubernetes.io/cluster/default" = "owned"
#  }
#}
#
#resource "null_resource" "k3os_master" {
#  count = "${var.sync_manifests ? 1 : 0}"
#
#  provisioner "file" {
#    source      = "${path.module}/manifests"
#    destination = "/home/rancher/"
#    connection {
#      type  = "ssh"
#      host  = "${aws_instance.k3os_master.public_dns}"
#      agent = true
#      user  = "rancher"
#    }
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "sleep 20",
#      "sudo k3s kubectl cordon ${aws_instance.k3os_master.private_dns}",
#      "sudo mv /home/rancher/manifests/* /var/lib/rancher/k3s/server/manifests/",
#      "sudo chown -R root:root /var/lib/rancher/k3s/server/manifests/",
#      "sudo chmod -R 0600 /var/lib/rancher/k3s/server/manifests/",
#      "sudo cp /etc/rancher/k3s/k3s.yaml /home/rancher/",
#      "sudo chown rancher:rancher /home/rancher/k3s.yaml"
#    ]
#    connection {
#      type        = "ssh"
#      host        = "${aws_instance.k3os_master.public_dns}"
#      agent       = true
#      user        = "rancher"
#      script_path = "/home/rancher/terraform.sh"
#    }
#  }
#
#  provisioner "local-exec" {
#    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null rancher@${aws_instance.k3os_master.public_dns}:~/k3s.yaml kubeconfig"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "rm /home/rancher/k3s.yaml"
#    ]
#    connection {
#      type        = "ssh"
#      host        = "${aws_instance.k3os_master.public_dns}"
#      agent       = true
#      user        = "rancher"
#      script_path = "/home/rancher/terraform.sh"
#    }
#  }
#
#}
#
