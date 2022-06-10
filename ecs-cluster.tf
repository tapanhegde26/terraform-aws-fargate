# create ecs cluster
resource "aws_ecs_cluster" "aws-ecs" {
  name = var.app_name
}

resource "aws_key_pair" "bat-cloud" {
  key_name   = var.aws_key_pair_name
  public_key = file(var.public_key_path)
}

# ecs cluster runner role policies
resource "aws_iam_role" "ecs-cluster-runner-role" {
  name               = "${var.app_name}-cluster-runner-role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs-cluster-runner-policy" {
  statement {
    actions   = ["ec2:Describe*", "ecr:Describe*", "ecr:BatchGet*"]
    resources = ["*"]
  }
  statement {
    actions   = ["ecs:*"]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.app_name}/*"]
  }
}

resource "aws_iam_role_policy" "ecs-cluster-runner-role-policy" {
  name   = "${var.app_name}-cluster-runner-policy"
  role   = aws_iam_role.ecs-cluster-runner-role.name
  policy = data.aws_iam_policy_document.ecs-cluster-runner-policy.json
}

resource "aws_iam_instance_profile" "ecs-cluster-runner-profile" {
  name = "${var.app_name}-cluster-runner-iam-profile"
  role = aws_iam_role.ecs-cluster-runner-role.name
}

# ec2 user data for hard drive
data "template_file" "user_data_cluster" {
  template = file("templates/cluster_user_data.sh")
  vars = {
    ecs_cluster = aws_ecs_cluster.aws-ecs.name
  }
}

# create ec2 instance for the ecs cluster runner
resource "aws_instance" "ecs-cluster-runner" {
  ami                         = "ami-0fa49cc9dc8d62c84"
  instance_type               = var.cluster_runner_type
  subnet_id                   = element(aws_subnet.aws-subnet.*.id, 0)
  vpc_security_group_ids      = [aws_security_group.ecs-cluster-host.id]
  associate_public_ip_address = true
  key_name                    = var.aws_key_pair_name
  user_data                   = data.template_file.user_data_cluster.rendered
  count                       = var.cluster_runner_count
  iam_instance_profile        = aws_iam_instance_profile.ecs-cluster-runner-profile.name

  tags = {
    Name        = "${var.app_name}-ecs-cluster-runner"
    Environment = var.app_environment
    Role        = "ecs-cluster"
  }

  volume_tags = {
    Name        = "${var.app_name}-ecs-cluster-runner"
    Environment = var.app_environment
    Role        = "ecs-cluster"
  }
}

# create security group and segurity rules for the ecs cluster
resource "aws_security_group" "ecs-cluster-host" {
  name        = "${var.app_name}-ecs-cluster-host"
  description = "${var.app_name}-ecs-cluster-host"
  vpc_id      = aws_vpc.aws-vpc.id
  tags = {
    Name        = "${var.app_name}-ecs-cluster-host"
    Environment = var.app_environment
    Role        = "ecs-cluster"
  }
}

resource "aws_security_group_rule" "ecs-cluster-host-ssh" {
  security_group_id = aws_security_group.ecs-cluster-host.id
  description       = "admin SSH access to ecs cluster"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_sources_cidr
}

resource "aws_security_group_rule" "ecs-cluster-egress" {
  security_group_id = aws_security_group.ecs-cluster-host.id
  description       = "ecs cluster egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# output ecs cluster public ip
output "ecs_cluster_runner_ip" {
  description = "External IP of ECS Cluster"
  value       = [aws_instance.ecs-cluster-runner.*.public_ip]
}
