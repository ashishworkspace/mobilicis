import boto3

def create_cloudwatch_alarm(instance_id):
    client = boto3.client('cloudwatch')
    
    alarm_name = 'HighCPUAlarm'
    alarm_description = 'Triggered when CPU usage exceeds 80% for 5 consecutive minutes'
    metric_name = 'CPUUtilization'
    namespace = 'AWS/EC2'
    comparison_operator = 'GreaterThanThreshold'
    threshold = 80.0
    evaluation_periods = 5
    period = 60
    statistic = 'Average'
    
    response = client.put_metric_alarm(
        AlarmName=alarm_name,
        AlarmDescription=alarm_description,
        MetricName=metric_name,
        Namespace=namespace,
        ComparisonOperator=comparison_operator,
        Threshold=threshold,
        EvaluationPeriods=evaluation_periods,
        Period=period,
        Statistic=statistic,
        Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}]
    )
    
    print('CloudWatch alarm created successfully.')

# Replace 'instance_id' with the actual EC2 instance ID you want to monitor
instance_id = 'i-07a95987303751db0'
create_cloudwatch_alarm(instance_id)
