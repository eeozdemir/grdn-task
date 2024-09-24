# Monitoring and Logging System

## Monitoring

We use AWS CloudWatch for monitoring and logging our EKS cluster and applications.

##  Setup

CloudWatch agent is deployed as a DaemonSet:

`
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-cloudwatch
        env:
          - name: REGION
            value: "eu-central-1"
          - name: CLUSTER_NAME
            value: "guardian-eks-cluster"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluentd-config
        configMap:
          name: fluentd-config
`

## Usage

Logs are automatically collected from all pods and sent to CloudWatch Logs.
Metrics are collected by the CloudWatch agent and sent to CloudWatch Metrics.
CloudWatch Dashboards are created to visualize key metrics:

`
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "EKS-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", "my-cluster"]
          ]
          period = 300
          stat   = "Maximum"
          region = "us-west-2"
          title  = "Failed Node Count"
        }
      },
      # ... (more widget definitions)
    ]
  })
}
`

Alarms are set up for critical metrics:

`
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
}
`

## Scaling and Auto-Healing Mechanisms

We use a combination of Kubernetes native features and AWS services for scaling and auto-healing.

## Horizontal Pod Autoscaler (HPA)

HPA is configured for each deployment:

`
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 50
`
