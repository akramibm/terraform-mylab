resource "aws_instance" "name" {

    ami = data.aws_ami.ami.id
    instance_type = var.instance_type
    security_groups = [data.aws_security_group.selected.name]   
    vpc_security_group_ids = [data.aws_security_group.selected.id]  

    tags = {
        Name = var.tool_name
    }
  
}

resource "aws_iam_role" "name" {

    name = "${var.tool_name}-role"
    assume_role_policy = jsonencode({ 
    
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Name = "${var.tool_name}-role"
    }
  
}

resource "aws_iam_role_policy" "name" {

    name = "${var.tool_name}-policy"
    role = aws_iam_role.name.id
    policy = jsonencode({
    
        Version = "2012-10-17"
        Statement = [
            {
                Action = concat(var.policy_resource_list, var.dummy_policy)
                Effect = "Allow"
                Resource = "*"
            }
        ]
    })
  
}

resource "aws_iam_instance_profile" "name" {

    name = "${var.tool_name}-instance-profile"
    role = aws_iam_role.name.name
  
}

resource "aws_route53_record" "public" {

    zone_id = var.zone_id
    name = "${var.tool_name}-public"
    type = "A"
    ttl = 3
    records = [aws_instance.name.public_ip]
  
}

resource "aws_route53_record" "private" {
    
    zone_id = var.zone_id
    name = "${var.tool_name}-private"
    type = "A"
    ttl = 3
    records = [aws_instance.name.private_ip]
  
}