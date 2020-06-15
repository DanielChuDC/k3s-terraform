provider "aws" {region = "us-east-2"}




variable "key_name" {
  default="sshkey_name"
}

locals {
  pub = ".pub"
  priv = ".priv"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096

    #---- Create key and write to local file
  provisioner "local-exec" {
    command = "cat > ${var.key_name} <<EOL\n${tls_private_key.example.private_key_pem}\nEOL"
  }
  # copy private key to local file named {key_name}.priv
  provisioner "local-exec" {
    command = "cp ${var.key_name} ${var.key_name}${local.priv}"
  }
  # save public key to {name}.pub
  provisioner "local-exec" {
    command = "cat > ${var.key_name}${local.pub} <<EOL\n${tls_private_key.example.public_key_openssh}\nEOL"
  }
  #---- Change privledges of key file
  provisioner "local-exec" {
    command = "chmod 600 ${var.key_name}"
  }
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.example.public_key_openssh}"
}

variable "resource_prefix" {
  default="k3s"
}

variable "ec2_instance_type" {
  default = "t2.xlarge"
}


resource "aws_security_group" "instances" {
  name        = "k3s-${var.resource_prefix}"
  description = "k3s-${var.resource_prefix}"
  vpc_id      = "${aws_vpc.mainvpc.id}"
  }

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "TCP"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instances.id}"
}
resource "aws_security_group_rule" "outbound_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instances.id}"
}

resource "aws_security_group_rule" "inbound_allow_all" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instances.id}"
}

resource "aws_security_group_rule" "kubeapi" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "TCP"
  self            = true  
  security_group_id = "${aws_security_group.instances.id}"

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"] # Ubuntu Minimal Bionic
    }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  }

resource "aws_instance" "server" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.ec2_instance_type}"
  # VPC
  subnet_id = "${aws_subnet.dev-subnet-public-1.id}"
  user_data = "${file("cloud-config-server.yml")}"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instances.id}"]
  tags = {
    Name = "${var.resource_prefix}-k3s-server"
  }
}

resource "aws_instance" "worker" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.ec2_instance_type}"
  user_data = "${file("cloud-config-worker.yml")}"
    # VPC
  subnet_id = "${aws_subnet.dev-subnet-public-1.id}"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instances.id}"]
  tags = {
    Name = "${var.resource_prefix}-k3s-worker"
  }
}
