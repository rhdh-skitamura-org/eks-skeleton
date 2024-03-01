module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = local.vpc.name
  cidr                 = local.vpc.cidr
  enable_dns_hostnames = true

  azs             = local.vpc.azs
  public_subnets  = local.vpc.public_subnets
  private_subnets = local.vpc.private_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # これがないと後ほど作成するALBが自動で作成されません。
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  tags = local.vpc.tags
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.eks.cluster_name
  cluster_version = local.eks.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  #control_plane_subnet_ids = module.vpc.infra_subnets 

  create_iam_role = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", ]
  }

  eks_managed_node_groups = local.eks.eks_managed_node_groups

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    default = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${local.eks_access_entry.principal_type}/${local.eks_access_entry.principal_name}"

      policy_associations = {
        default = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

#resource aws_eks_access_entry entry {
#  cluster_name      = module.eks.cluster_name
#  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${local.eks_access_entry.principal_type}/${local.eks_access_entry.principal_name}"
#  type              = "STANDARD"
#}
#
#resource aws_eks_access_policy_association access_policy_association {
#  cluster_name  = module.eks.cluster_name
#  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#                   arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
#  principal_arn = aws_eks_access_entry.entry.access_entry_arn
#
#  access_scope {
#    type       = "cluster"
#  }
#}
