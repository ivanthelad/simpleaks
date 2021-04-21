    volumeMounts:
    - mountPath: /tmp
      name: forappinsights
  volumes:
  - name: forappinsights
    emptyDir: {}

