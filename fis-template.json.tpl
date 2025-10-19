{
  "description": "Inject network delay/loss to a percentage of test EC2s",
  "targets": {
    "ec2Target": {
      "resourceType": "aws:ec2:instance",
      "resourceTags": {
        "${tag_key}": "${tag_value}"
      },
      "selectionMode": "PERCENT",
      "resourceCount": "${affected_percent}"
    }
  },
  "actions": {
    "injectLatency": {
      "actionId": "aws:ec2:network-delay",
      "description": "Inject ${latency_ms}ms delay and ${loss_percent}% packet loss",
      "parameters": {
        "duration": "PT${duration_sec}S",
        "delay": "${latency_ms}",
        "loss": "${loss_percent}"
      },
      "targets": {
        "Instances": "ec2Target"
      }
    }
  },
  "stopConditions": [
    {
      "source": "none"
    }
  ],
  "roleArn": "${role_arn}"
}
