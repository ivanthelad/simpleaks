
kubrnetes events 
https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/events/event.go



## Configure a better threshold 
alertable_metrics_configuration_settings.container_resource_utilization_thresholds]

## https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-metric-alerts

let endDateTime = now(); 
let startDateTime = ago(1h);
let trendBinSize = 1m;
let clusterName = 'kafka-e21b7';
KubePodInventory
    | where TimeGenerated < endDateTime
    | where TimeGenerated >= startDateTime
 //   | where ClusterName == clusterName
    | distinct ClusterName, TimeGenerated
    | summarize ClusterSnapshotCount = count() by bin(TimeGenerated, trendBinSize), ClusterName
    | join hint.strategy=broadcast (
        KubePodInventory
        | where TimeGenerated < endDateTime
        | where TimeGenerated >= startDateTime
        | summarize PodStatus=any(PodStatus) by TimeGenerated, PodUid, ClusterName
        | summarize TotalCount = count(),
                    Failed                           = sumif(1, PodStatus =~ 'Failed'),
                    Killing                          = sumif(1, PodStatus =~ 'Killing'),
                    Preempting                       = sumif(1, PodStatus =~ 'Preempting'),
                    ExceededGracePeriod              = sumif(1, PodStatus =~ 'ExceededGracePeriod'),
                    FailedKillPod                    = sumif(1, PodStatus =~ 'FailedKillPod'),
                    FailedCreatePodContainer         = sumif(1, PodStatus =~ 'FailedCreatePodContainer'),
                    NetworkNotReady                  = sumif(1, PodStatus =~ 'NetworkNotReady'),
                    ErrImageNeverPull                = sumif(1, PodStatus =~ 'ErrImageNeverPull'),
                    BackOff                          = sumif(1, PodStatus =~ 'BackOff'),
                    NodeNotReady                     = sumif(1, PodStatus =~ 'NodeNotReady'),
                    NodeNotSchedulable               = sumif(1, PodStatus =~ 'NodeNotSchedulable'),
                    KubeletSetupFailed               = sumif(1, PodStatus =~ 'KubeletSetupFailed'),
                    FailedAttachVolume               = sumif(1, PodStatus =~ 'FailedAttachVolume'),
                    VolumeResizeFailed               = sumif(1, PodStatus =~ 'VolumeResizeFailed'),
                    FailedMount                      = sumif(1, PodStatus =~ 'FailedMount'),
                    FileSystemResizeFailed           = sumif(1, PodStatus =~ 'FileSystemResizeFailed'),
                    FailedMapVolume                  = sumif(1, PodStatus =~ 'FailedMapVolume'),
                    AlreadyMountedVolume             = sumif(1, PodStatus =~ 'AlreadyMountedVolume'),
                    ContainerGCFailed                = sumif(1, PodStatus =~ 'ContainerGCFailed'),
                    ImageGCFailed                    = sumif(1, PodStatus =~ 'ImageGCFailed'),
                    FailedNodeAllocatableEnforcement = sumif(1, PodStatus =~ 'FailedNodeAllocatableEnforcement'),
                    FailedCreatePodSandBox           = sumif(1, PodStatus =~ 'FailedCreatePodSandBox'),
                    FailedPodSandBoxStatus           = sumif(1, PodStatus =~ 'FailedPodSandBoxStatus'),
                    FailedMountOnFilesystemMismatch  = sumif(1, PodStatus =~ 'FailedMountOnFilesystemMismatch'),
                    InvalidDiskCapacity              = sumif(1, PodStatus =~ 'InvalidDiskCapacity'),
                    FreeDiskSpaceFailed              = sumif(1, PodStatus =~ 'FreeDiskSpaceFailed'),
                    Unhealthy                        = sumif(1, PodStatus =~ 'ProbeWarning'),
                    FailedPostStartHook              = sumif(1, PodStatus =~ 'FailedPostStartHook'),
                    FailedPreStopHook                = sumif(1, PodStatus =~ 'FailedPreStopHook'),
                    FailedSync                       = sumif(1, PodStatus =~ 'FailedSync')
                by ClusterName, bin(TimeGenerated, trendBinSize)
    ) on ClusterName, TimeGenerated
    | extend UnknownCount = TotalCount - Failed - Killing - Preempting - FailedCount
    | project TimeGenerated,
              TotalCount = todouble(TotalCount) / ClusterSnapshotCount,
              PendingCount = todouble(PendingCount) / ClusterSnapshotCount,
              RunningCount = todouble(RunningCount) / ClusterSnapshotCount,
              SucceededCount = todouble(SucceededCount) / ClusterSnapshotCount,
              FailedCount = todouble(FailedCount) / ClusterSnapshotCount,
              UnknownCount = todouble(UnknownCount) / ClusterSnapshotCount

            Failed                          = todouble(Failed) / ClusterSnapshotCount,
            Killing                         = todouble(Killing) / ClusterSnapshotCount,
            Preempting                      = todouble(Preempting) / ClusterSnapshotCount,
            BackOff                         = todouble(BackOff) / ClusterSnapshotCount,
            ExceededGracePeriod             = todouble(ExceededGracePeriod) / ClusterSnapshotCount,
            FailedKillPod                   = todouble(FailedKillPod) / ClusterSnapshotCount,
            FailedCreatePodContainer        = todouble(FailedCreatePodContainer) / ClusterSnapshotCount,
            NetworkNotReady                 = todouble(NetworkNotReady) / ClusterSnapshotCount,
            ErrImageNeverPull               = todouble(ErrImageNeverPull) / ClusterSnapshotCount,
            BackOff                         = todouble(BackOff) / ClusterSnapshotCount,
            NodeNotReady                    = todouble(NodeNotReady) / ClusterSnapshotCount,
            NodeNotSchedulable              = todouble(NodeNotSchedulable) / ClusterSnapshotCount,
            KubeletSetupFailed              = todouble(KubeletSetupFailed) / ClusterSnapshotCount,
            FailedAttachVolume              = todouble(FailedAttachVolume) / ClusterSnapshotCount,
            VolumeResizeFailed              = todouble(VolumeResizeFailed) / ClusterSnapshotCount,
            FailedMount                     = todouble(FailedMount) / ClusterSnapshotCount,
            FileSystemResizeFailed          = todouble(FileSystemResizeFailed) / ClusterSnapshotCount,
            FailedMapVolume                 = todouble(FailedMapVolume) / ClusterSnapshotCount,
            AlreadyMountedVolume            = todouble(AlreadyMountedVolume) / ClusterSnapshotCount,
            ContainerGCFailed               = todouble(ContainerGCFailed) / ClusterSnapshotCount,
            ImageGCFailed                   = todouble(ImageGCFailed) / ClusterSnapshotCount,
            FailedNodeAllocatableEnforcement= todouble(FailedNodeAllocatableEnforcement ) / ClusterSnapshotCount,
            FailedCreatePodSandBox          = todouble(FailedCreatePodSandBox) / ClusterSnapshotCount,
            FailedPodSandBoxStatus          = todouble(FailedPodSandBoxStatus) / ClusterSnapshotCount,
            FailedMountOnFilesystemMismatch = todouble(FailedMountOnFilesystemMismatch) / ClusterSnapshotCount,
            InvalidDiskCapacity             = todouble(InvalidDiskCapacity) / ClusterSnapshotCount,
            FreeDiskSpaceFailed             = todouble(FreeDiskSpaceFailed) / ClusterSnapshotCount,
            Unhealthy                       = todouble(Unhealthy) / ClusterSnapshotCount,
            FailedPostStartHook             = todouble(FailedPostStartHook) / ClusterSnapshotCount,
            FailedPreStopHook               = todouble(FailedPreStopHook) / ClusterSnapshotCount,
            FailedSync                      = todouble(FailedSync) / ClusterSnapshotCount,
| summarize AggregatedValue = avg(PendingCount) by bin(TimeGenerated, trendBinSize)