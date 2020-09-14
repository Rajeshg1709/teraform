
# Create VPC/Subnet/Security Group/Network ACL
provider "aws" {
  version = "~> 2.0"
  access_key = ""
  secret_key = ""
  region     = "ap-south-1"
}
# create the VPC
resource "aws_vpc" "Test_VPC" {
  cidr_block           = "11.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
tags = {
    Name = "Test_VPC"
}
} # end resource
# create the Subnet
resource "aws_subnet" "Public_subnet_1" {
  vpc_id                  = aws_vpc.Test_VPC.id
  cidr_block              = "11.0.0.0/26"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
tags = {
   Name = "Public_subnet_1"
}
} # end resource

# create the Subnet
resource "aws_subnet" "Public_subnet_2" {
  vpc_id                  = aws_vpc.Test_VPC.id
  cidr_block              = "11.0.0.64/26"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"
tags = {
   Name = "Public_subnet_2"
}
} # end resource

# create the Subnet
resource "aws_subnet" "Private_subnet_1" {
  vpc_id                  = aws_vpc.Test_VPC.id
  cidr_block              = "11.0.1.0/26"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1c"
tags = {
   Name = "Private_subnet_1"
}
} # end resource

# create the Subnet
resource "aws_subnet" "Private_subnet_2" {
  vpc_id                  = aws_vpc.Test_VPC.id
  cidr_block              = "11.0.1.64/26"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1c"
tags = {
   Name = "Private_subnet_2"
}
} # end resource


# Create the Security Group
resource "aws_security_group" "Test_VPC_Security_Group" {
  vpc_id       = aws_vpc.Test_VPC.id
  name         = "Test_VPC_Security Group"
  description  = "Test_VPC_Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
   # allow ingress of port 80
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
   # allow ingress of port 443
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "Test_VPC_Security Group"
   Description = "Test_VPC_Security Group"
}
} # end resource

resource "aws_security_group" "Test_VPC_sg_private" {
  vpc_id       = aws_vpc.Test_VPC.id
  name         = "Test_VPC_sg_private"
  description  = "Test_VPC_sg_private"

  
  ingress {
    security_groups = ["${aws_security_group.Test_VPC_Security_Group.id}"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    security_groups = ["${aws_security_group.Test_VPC_Security_Group.id}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
}
  
    ingress {
    security_groups = ["${aws_security_group.Test_VPC_Security_Group.id}"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
}
  egress {
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
}
tags = {
   Name = "Test_VPC_sg_private"
   Description = "Test_VPC_sg_private"
}
} # end resource



# Create the Internet Gateway
resource "aws_internet_gateway" "Test_VPC_GW" {
 vpc_id = aws_vpc.Test_VPC.id
 tags = {
        Name = "Test_VPC_GW"
}
} # end resource

# Create the Route Table
resource "aws_route_table" "Test_VPC_route_table" {
 vpc_id = aws_vpc.Test_VPC.id
 tags = {
        Name = "Test_VPC_route_table"
}
} # end resource

# Create the Internet Access
resource "aws_route" "Test_VPC_internet_access" {
  route_table_id         = aws_route_table.Test_VPC_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Test_VPC_GW.id
} # end resource

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Test_VPC_association" {
  subnet_id      = aws_subnet.Public_subnet_1.id
  route_table_id = aws_route_table.Test_VPC_route_table.id
} # end resource

resource "aws_instance" "ubuntu_wordpress" {
    ami = "ami-0e9182bc6494264a4"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.Test_VPC_Security_Group.id}"]
    subnet_id = aws_subnet.Public_subnet_1.id
    key_name = "mykey"
   
    associate_public_ip_address = true
    ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 8
  }
    tags = {
      Name              = "ub-wordpress"
      Environment       = "test"
      Project           = "test-proj"
    }
    
    provisioner "file" {
    source      = "./myinstall.sh"
    destination = "/home/ubuntu/myinstall.sh"
  }
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ubuntu/wpinstall.sh",
      "sudo sh /home/ubuntu/myinstall.sh",
    ]
}
connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = file("./mykey.pem")
    host        = self.public_ip
  }
 
}

resource  "aws_ami_from_instance" "ubuntu_wordpress-ami" {
    name               = "ubuntu_wordpress-ami"
    source_instance_id = aws_instance.ubuntu_wordpress.id 

  depends_on = [
      aws_instance.ubuntu_wordpress,
      ]

  tags = {
      Name = "ubuntu_wordpress-ami"
  }

}

resource "aws_launch_configuration" "launch-config" {
  name_prefix         = "launch-config"
  image_id      = aws_ami_from_instance.ubuntu_wordpress-ami.id
  instance_type = "t2.micro"
  root_block_device {
    delete_on_termination = false
    encrypted = true
  }

}

resource "aws_autoscaling_group" "autoscaling-grp" {
  name                      = "autoscaling-grp"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.launch-config.name
  vpc_zone_identifier       = [aws_subnet.Private_subnet_1.id, aws_subnet.Private_subnet_2.id]
}

resource "aws_lb_target_group" "trg-wordpress" {
  name     = "trg-wordpress"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Test_VPC.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 10
    matcher             = 200
  }

}

resource "aws_lb_target_group_attachment" "trg-attachment" {
  target_group_arn = aws_lb_target_group.trg-wordpress.arn
  target_id        = aws_instance.ubuntu_wordpress.id
  port             = 80
}


resource "aws_lb" "lb-wordpress" {
  name               = "lb-wordpress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Test_VPC_Security_Group.id]
  subnets            = [aws_subnet.Public_subnet_1.id, aws_subnet.Public_subnet_2.id]

  enable_deletion_protection = true
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb-wordpress.arn
  port              = "80"
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.trg-wordpress.arn
  }
}




