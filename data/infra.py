from diagrams import Diagram, Cluster, Node, Edge
from diagrams.aws.compute import ECS, Fargate, ElasticContainerServiceContainer
from diagrams.aws.storage import EFS
from diagrams.aws.database import RDS
from diagrams.aws.management import Cloudwatch, SystemsManager, AutoScaling
from diagrams.aws.security import ACM, IAM, CertificateManager
from diagrams.aws.network import ELB, VPC, InternetGateway, NATGateway, PrivateSubnet, PublicSubnet, Route53
from diagrams.generic.network import Firewall
from diagrams.aws.general import Users
from diagrams.programming.framework import Django

# グラフ属性
graph_attr = {
    "fontsize": "25",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho"
}

# タスクコンテナ用のクラスター属性
task_attr = {
    "fontsize": "16",
    "style": "rounded",
    "bgcolor": "#F8F8FF",
    "penwidth": "1.5",
    "pencolor": "#4B0082"
}

with Diagram("AWS Infrastructure with Cloudflare", show=True, graph_attr=graph_attr):
    users = Users("Users")

    # Cloudflare Configuration
    with Cluster("Cloudflare"):
        cloudflare_dns = Firewall("Cloudflare DNS\nProxy Enabled")
        cloudflare_cert = CertificateManager("DNS Validation")
    
    # Certificate
    cert = ACM("ACM Certificate")
    
    # Systems Manager
    ssm = SystemsManager("Parameter Store")

    with Cluster("VPC - 10.0.0.0/16"):
        # Load Balancer
        alb = ELB("ALB")

        # Internet Gateway
        igw = InternetGateway("Internet Gateway")
        
        with Cluster("Availability Zone a"):
            with Cluster("Public Subnet a - 10.0.1.0/24"):
                public_a = PublicSubnet("Public Subnet")
                nat_a = NATGateway("NAT Gateway")
                
            with Cluster("Private Subnet a - 10.0.11.0/24"):
                private_a = PrivateSubnet("Private Subnet")

        with Cluster("Availability Zone c"):
            with Cluster("Public Subnet c - 10.0.2.0/24"):
                public_c = PublicSubnet("Public Subnet")
                nat_c = NATGateway("NAT Gateway")
                
            with Cluster("Private Subnet c - 10.0.12.0/24"):
                private_c = PrivateSubnet("Private Subnet")

        with Cluster("ECS Cluster"):
            # IAM Roles
            task_role = IAM("Task Role")
            exec_role = IAM("Execution Role")
            
            # Fargate and AutoScaling
            fargate = Fargate("Fargate Runtime\nCPU: 1024\nMemory: 2048")
            asg = AutoScaling("Auto Scaling\nmin: 1, max: 4\nCPU: 80%")

            with Cluster("ECS Service (Desired: 2)"):
                # Individual task containers with their own clusters
                with Cluster("Task Container 1", graph_attr=task_attr):
                    container1 = ElasticContainerServiceContainer("Nginx + Django")
                
                with Cluster("Task Container 2", graph_attr=task_attr):
                    container2 = ElasticContainerServiceContainer("Nginx + Django")

        # Persistent Storage
        efs = EFS("EFS\nstatic & media")
        rds = RDS("RDS PostgreSQL\ndb.t3.small")
        
        # Monitoring
        cw = Cloudwatch("CloudWatch Logs")

    # External traffic flow
    users >> Edge(color="orange") >> cloudflare_dns
    cloudflare_dns >> Edge(color="orange") >> alb
    
    # Certificate validation
    cert - Edge(style="dashed") - cloudflare_cert
    cert >> alb
    
    # Network flow
    igw >> Edge(color="blue") >> [public_a, public_c]
    public_a >> Edge(color="blue") >> nat_a >> Edge(color="blue") >> private_a
    public_c >> Edge(color="blue") >> nat_c >> Edge(color="blue") >> private_c
    
    # Service placement
    private_a - [container1, container2]
    private_c - [container1, container2]
    
    # Load balancer to containers
    alb >> [container1, container2]
    
    # Container relationships
    for container in [container1, container2]:
        fargate >> container
        task_role >> container
        exec_role >> container
        container >> efs
        container >> rds
        container >> cw
        asg >> container
        ssm >> container