let endDateTime = now();
let startDateTime = ago(10h);
let trendBinSize = 5m;
let capacityCounterName = 'memoryLimitBytes';
let usageCounterName = 'memoryRssBytes';

KubePodInventory
| where TimeGenerated < endDateTime
| where TimeGenerated >= startDateTime
| where "a" == "a"
| where ControllerKind in ('DaemonSet', 'ReplicaSet')
| where Namespace in ('prod', 'dev')
| extend InstanceName = strcat(ClusterId, '/', ContainerName),
    PodName=Name
| where PodStatus in ('Running', 'Terminating')
| distinct Computer, InstanceName, ContainerName, PodName,ControllerName
| join hint.strategy=shuffle (
    Perf
    | where TimeGenerated < endDateTime
    | where TimeGenerated >= startDateTime
    | where ObjectName == 'K8SContainer'
    | where CounterName == capacityCounterName
    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)
    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue
    )
    on Computer, InstanceName
| join kind=inner hint.strategy=shuffle (
    Perf
    | where TimeGenerated < endDateTime + trendBinSize
    | where TimeGenerated >= startDateTime - trendBinSize
    | where ObjectName == 'K8SContainer'
    | where CounterName == usageCounterName
    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated
    )
    on Computer, InstanceName
| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime
| project Computer, ContainerName,PodName,ControllerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue, UsageValue, LimitValue
| union ( // 1
  range x from 1 to 1 step 1 // 2
  | mv-expand Timestamp=range(startDateTime, endDateTime, trendBinSize) to typeof(datetime) // 3
  | extend AggregatedValue=0 // 4
  )
| summarize AggregatedValue=max(AggregatedValue) by bin(TimeGenerated, trendBinSize) , ControllerName 
| render timechart 
