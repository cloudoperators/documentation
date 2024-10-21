# Frequently Asked Questions

### Is Greenhouse a managed service?

No. Greenhouse enables teams to operate their Kubernetes clusters using CCloud best practices.

### How do LoBs use Greenhouse?

### How does Greenhouse compare to Kyma?

There’s plenty of tools that can be used to deploy tools such as Prometheus. However, they don’t provide an end-to-end process. Greenhouse does by wiring plugins together and providing (codified) guidance for the Plugins. For example: The kube-monitoring plugin provides end-to-end monitoring from alerts, playbooks, dashboards that work with the Prometheus, Alertmanager, Thanos, Supernova, etc. .

### Is Greenhouse replacing Concourse?

No. Greenhouse aims to make deployment of operational content (alerts, playbooks, dashboards) easy. Concourse and the CE deployment process is not touched. 

### Will Greenhouse replace the ukt for deploying into clusters?

### What is a plugin?

Plugins extend the capabilities of the core platform.

A plugin can consist of a back- and frontend. The backend is codified operational knowledge (alerts, playbooks, dashboards, configuration) or selected tools (Prometheus, Plutono, etc.). The frontend is shown in the Greenhouse UI. 

### What is an extension?

The terminology is plugin.

### What is the difference between plugin and extension?

The term is plugin.

### Will Ceph be managed in Greenhouse?

No. Greenhouse is an operations platform and does not manage Ceph. Greenhouse deploys Ceph alerts, playbooks, dashboards to the Ceph Kubernetes clusters.

### Who supports the monitoring stack in OpenStack, Ceph, KVM, and all other flavors of clusters used for CCloud?

Team Observability supports the plugins for the foundational monitoring components (Prometheus/Thanos, Alert manager, ...)

### Where can I find a matrix of which support group owns which plugin?

### Who to contact for general questions regarding Greenhouse?

Arno Uhlig, Ivo Gosemann or general questions via the #greenhouse channel in Slack.