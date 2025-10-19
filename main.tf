provider "aws" {
  region = var.region
}

# デフォルトVPC
data "aws_vpc" "default" {
  default = true
}

# デフォルトVPC内サブネット
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# SSH鍵生成
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "tf-generated-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/tf_generated_key.pem"
  file_permission = "0600"
}

# ------------------------
# 現在のIPからSSH接続を許可するセキュリティグループ
# ------------------------
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

resource "aws_security_group" "ssh_sg" {
  name   = "allow-ssh-from-my-ip"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH from current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-from-my-ip"
  }
}

# ------------------------
# EC2作成
# ------------------------
resource "aws_instance" "example" {
  count                  = var.pc_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[count.index % length(data.aws_subnets.default.ids)]
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name    = "tf-ec2-${count.index + 1}"
    FISTest = "true" # ← ★ 追加（FISターゲット指定用タグ）
  }
}

# ------------------------
# SSH接続用Output
# ------------------------
output "ssh_private_cmds" {
  description = "SSH commands to connect to all EC2 instances"
  value = [
    for i in aws_instance.example :
    "ssh -i ${local_file.private_key_pem.filename} ec2-user@${i.public_ip}"
  ]
  sensitive = true
}

# ------------------------
# FIS用JSONテンプレート生成
# ------------------------
# ネットワーク注入パラメータ（環境変数 TF_VAR_ で上書き可）
variable "network_latency_ms" {
  description = "遅延（ms）"
  type        = number
  default     = 100
}

variable "network_error_rate" {
  description = "エラー率（0〜1）"
  type        = number
  default     = 0.01
}

variable "affected_pc_ratio" {
  description = "遅延・パケットロスを注入する EC2 の割合（0〜1 の小数）"
  type        = number
  default     = 0.2
}

variable "inject_duration_seconds" {
  description = "注入を維持する秒数（例: 600 = 10分）"
  type        = number
  default     = 600
}

# ------------------------
# FIS用IAMロール
# ------------------------
resource "aws_iam_role" "fis_role" {
  name = "tf-fis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "fis.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fis_policy" {
  name = "tf-fis-role-policy"
  role = aws_iam_role.fis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:ModifyInstanceAttribute",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# 異常事態シナリオ（固定値）
locals {
  # 通常テスト（環境変数で制御）
  fis_template_normal = templatefile("${path.module}/fis-template.json.tpl", {
    latency_ms       = var.network_latency_ms
    loss_percent     = var.network_error_rate * 100
    duration_sec     = var.inject_duration_seconds
    affected_percent = var.affected_pc_ratio * 100
    tag_key          = "FISTest"
    tag_value        = "true"
    role_arn         = aws_iam_role.fis_role.arn
  })

  # 異常事態（強い遅延・高い損失率）
  fis_template_abnormal = templatefile("${path.module}/fis-template.json.tpl", {
    latency_ms       = 2000 # 2秒遅延
    loss_percent     = 30   # 30%パケットロス
    duration_sec     = 600  # 10分間
    affected_percent = 50   # 半数のEC2に注入
    tag_key          = "FISTest"
    tag_value        = "true"
    role_arn         = aws_iam_role.fis_role.arn
  })
}

# それぞれをJSONファイルとして出力
resource "local_file" "fis_json_normal" {
  content  = local.fis_template_normal
  filename = "${path.module}/fis-template-normal.json"
}

resource "local_file" "fis_json_abnormal" {
  content  = local.fis_template_abnormal
  filename = "${path.module}/fis-template-abnormal.json"
}

# ------------------------
# FIS開始用CLI出力（3パターン）
# ------------------------
output "fis_start_commands" {
  description = "3種類のテスト用FISコマンド"
  value = {
    normal   = "aws fis create-experiment-template --cli-input-json file://${local_file.fis_json_normal.filename}"
    abnormal = "aws fis create-experiment-template --cli-input-json file://${local_file.fis_json_abnormal.filename}"
    ideal    = "echo 'No FIS injection (ideal baseline test)'"
  }
}
