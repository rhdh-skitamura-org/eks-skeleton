locals {
  project    = "${{ values.cluster_name }}"
  aws_region = "${{ values.aws_region }}"

  base_tags = {
    terraform = "true"
    eks       = "${{ values.cluster_name }}"
  }

  vpc = {
    name = "${{ values.cluster_name }}-vpc"
    cidr = "${{ values.vpc_cidr }}"

    azs = [
      "${{ values.az_1 }}",
      "${{ values.az_2 }}",
      "${{ values.az_3 }}"
    ]

    public_subnets = [
      "${{ values.public_subnet_1 }}",
      "${{ values.public_subnet_2 }}",
      "${{ values.public_subnet_3 }}",
    ]

    private_subnets = [
      "${{ values.private_subnet_1 }}",
      "${{ values.private_subnet_2 }}",
      "${{ values.private_subnet_3 }}",
    ]

    tags = {
      Terraform = "true",
    }
  }

  eks = {
    cluster_name    = local.project
    cluster_version = "${{ values.cluster_version }}"

    eks_managed_node_groups = {
      "${{ values.cluster_name }}-nodegroup" = {
        min_size     = ${{ values.node_group_min_size }}
        max_size     = ${{ values.node_group_max_size }}
        desired_size = ${{ values.node_group_desired_size }}

        instance_types = [
          "${{ values.node_group_instance_type }}"
        ]

        #capacity_type = "SPOT"
      }
    }
  }

  eks_access_entry = {
    principal_type = "${{ values.iam_principal_type }}"
    principal_name = "${{ values.iam_principal_name }}"
  }
}
