# Knative is not for serverless functions only!

Maybe you think that [Knative](https://knative.dev) is only useful for serverless functions,
but that's not the case. Not only Knative simplifies the way you deploy
your Kubernetes app (writing less YAML is great for your mental health!),
but you also get new features such as
[autoscaling](https://knative.dev/docs/serving/autoscaling/) for free.

This project shows how to convert an existing Kubernetes app to Knative.
In this repository, you'll only find manifests, not source code: find more at
[github.com/alexandreroman/k8s-todo-app](https://github.com/alexandreroman/k8s-todo-app)
to learn about the app.

![Application screenshot](/images/app.png)

This app is made of several components:

- **frontend**: a nginx container hosting HTML / JS / CSS files, leveraging Vue.js
- **backend**: a Spring Boot app exposing a simple REST API for getting / storing todo entries
- **database**: a PostgreSQL database instance storing todo entries
- **API gateway**: a Spring Cloud Gateway instance in front of all components, which is the only entry point behind an ingress route

Starting from the existing app architecture, this Knative variant replaces existing
Kubernetes deployments / services with
[Knative services](https://knative.dev/docs/serving/).

![Application architecture](/images/architecture.png)

You end up with Knative services for the frontend and backend components.
Pod instances for these components are created when you actually use the app:
should you stop using the app, these pod instances would be automatically destroyed.

Look at the [Knative service definitions](config/kservice.yml):
you can reuse the `template` section from your existing `Deployment` definitions
(`image`, `env`, `volumes`, etc), but you don't need to include liveness/readiness probes
nor `Service` definitions, since those features are covered by Knative.

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: frontend
  namespace: kn-todo
  labels:
    networking.knative.dev/visibility: cluster-local
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: alexandreroman/kn-todo-frontend
        resources:
          requests:
            memory: 256M
          limits:
            memory: 256M
```

## Prerequisites

Please read [this page about prerequisites](https://github.com/alexandreroman/k8s-todo-app#prerequisites) first.

This project has been tested with
[Cloud Native Runtimes](https://tanzu.vmware.com/content/blog/cloud-native-runtimes-for-vmware-tanzu-advanced-ga), a Knative distribution from
[VMware Tanzu](https://tanzu.vmware.com/). You may use any Knative 0.23+ distribution.

## How to use it?

This project relies on [ytt](https://carvel.dev/ytt/) to generate Kubernetes manifests
which fit your environment.

Please read [this page](https://github.com/alexandreroman/k8s-todo-app#how-to-use-it)
to find out how to deploy this app, since this repository uses the same configuration layout.

## Load testing the app and see Knative autoscaling in action

This repo includes scripts for load testing the app, leveraging
[Vegeta](https://github.com/tsenart/vegeta).
You need to install this tool first on your workstation.

Start load testing with these scripts:

```shell
./load-testing/load-testing-frontend.sh kn-todo.example.com
```

```shell
./load-testing/load-testing-backend.sh kn-todo.example.com
```

New pods will be created by Knative depending on the number of requests
received by each component.

You may want to tune autoscaling settings by editing the configuration file
for your environment:

```yaml
#! Set the max number of instances for each component.
BACKEND_SCALING_MAX: 8
FRONTEND_SCALING_MAX: 2

#! Set the target request per second for each component.
BACKEND_RPS_MAX: 50
FRONTEND_RPS_MAX: 200
```

### Using kapp to deploy the app

[kapp is part of the Carvel toolsuite](https://carvel.dev/kapp), along with `ytt`.
It's a great tool for managing resources (pod, deployment, service, etc.)
for your Kubernetes app: all those elements are regrouped under a single
"application", with resource ordering.

You can combine `ytt` with `kapp` to deploy this app.
For example:

```shell
kapp deploy -a kn-todo-dev -c -f <(ytt -f config -f config-env/dev -f config-ext/ingress.yml -f config-ext/ingress-tls.yml)
```

`kapp` displays the resources that you're about to deploy (with diff support),
and also monitors deployment, unlike `kubectl`: the command will wait on
the resources to become available before terminating.

A great companion to `ytt`!

## Contribute

Contributions are always welcome!

Feel free to open issues & send PR.

## License

Copyright &copy; 2021 [VMware, Inc. or its affiliates](https://vmware.com).

This project is licensed under the [Apache Software License version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
