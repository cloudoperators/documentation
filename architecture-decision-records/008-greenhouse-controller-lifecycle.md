# 008 Greenhouse Controller Lifecycle

- Status: proposed
- Deciders: Ivo Gosemann, Uwe Mayer, David Gogl, Abhijith Ravindra
- Date: 2024-10-18
- Tags: greenhouse
- Technical Story: [greenhouse#414](https://github.com/cloudoperators/greenhouse/issues/414)

## Context and Problem Statement

Greenhouse contains multiple controllers for custom resources such as `Organization`, `Cluster`, `Plugin`, etc. 

These controllers need a unified approach for their reconciliation lifecycle.

Therefore, this ADR addresses the following concerns:

- A standard reconcile interface that should be adopted by existing controllers and all new controllers.
- A common place to set the status of the resource as proposed by the ADR [004 Greenhouse Resource States](004-greenhouse-resource-status-reporting.md).


## Decision Drivers

- Uniformity:
    * All controllers implement the same interface for reconciliation.
    * Reducing code duplication

- Expandability:
    * Existing controllers should be easily able to adopt the interface.

- Ease of use:
    * New controllers should be able to implement the interface with minimal effort.

- Simplicity:
    * Controllers adopting the interface do not need to implement the reconciliation logic themselves.
    * `Create / Update` and `Delete` logic is separated.

## Decision Outcome

As described in the issue [greenhouse#414](https://github.com/cloudoperators/greenhouse/issues/414) we will introduce a `Reconciler` interface that controllers can implement.

## Reconciler and RuntimeObject Interface

The RuntimeObject interface allows the `Reconciler` to work with any CR object in a generic way, allowing the reconciler to access `DeepCopyObject` and the `ObjectMeta` of the CR object - `GetNamespace()`, `GetName()`, etc.

https://github.com/cloudoperators/greenhouse/blob/bb57e128014102f963c9879ef78af80bc1820bd4/pkg/lifecycle/reconcile.go#L48-L56

The `Reconciler` interface will have the following methods `EnsureCreated` and `EnsureDeleted` that the calling controller should implement.

https://github.com/cloudoperators/greenhouse/blob/bb57e128014102f963c9879ef78af80bc1820bd4/pkg/lifecycle/reconcile.go#L58-L62

`Reconcile` - is a generic function that is used to reconcile the state of a resource
It standardizes the reconciliation loop and provides a common way to set finalizers, remove finalizers, and update the status of the resource

It splits the reconciliation into two phases, `EnsureCreated` and `EnsureDeleted` to keep the `create / update` and `delete` logic in controllers segregated

https://github.com/cloudoperators/greenhouse/blob/bb57e128014102f963c9879ef78af80bc1820bd4/pkg/lifecycle/reconcile.go#L64-L135

Some controllers need to calculate their `ReadyCondition` based on certain criteria, in such cases a function of the type `Conditioner` can be passed to the `Reconcile` function.

```go
type Conditioner func(context.Context, RuntimeObject)
```

At the end of reconciliation, the status of the resource is patched by merging the original object stored in the context with the modified object.

https://github.com/cloudoperators/greenhouse/blob/bb57e128014102f963c9879ef78af80bc1820bd4/pkg/lifecycle/reconcile.go#L174-L184

## Interface Adoption

Controllers that need to adopt the `Reconciler` interface should first implement the `RuntimeObject` interface for their respective CR object.

ex: `Cluster` CR object

```go
func (c *Cluster) GetConditions() StatusConditions {
	return c.Status.StatusConditions
}

func (c *Cluster) SetCondition(condition Condition) {
	c.Status.StatusConditions.SetConditions(condition)
}
```

Then the controller should implement the `Reconciler` interface from `lifecycle` package

```go
func (r *RemoteClusterReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	return lifecycle.Reconcile(ctx, r.Client, req.NamespacedName, &greenhousev1alpha1.Cluster{}, r, <statusFunc>)
}
```

> Note: If no statusFunc is passed then `lifecycle` package will set default status based on the result of `EnsureCreated`.

The `EnsureCreated` and `EnsureDeleted` methods should be implemented in the controller so that the `Reconcile` function can call them.

```go
func (r *RemoteClusterReconciler) EnsureCreated(ctx context.Context, resource lifecycle.RuntimeObject) (ctrl.Result, lifecycle.ReconcileResult, error) {
    cluster := resource.(*greenhousev1alpha1.Cluster)
    ....
	return ctrl.Result{}, lifecycle.Success, nil
```

```go
func (r *RemoteClusterReconciler) EnsureDeleted(ctx context.Context, resource lifecycle.RuntimeObject) (ctrl.Result, lifecycle.ReconcileResult, error) {
    cluster := resource.(*greenhousev1alpha1.Cluster)
    ....
    return ctrl.Result{}, lifecycle.Success, nil
}
```

`lifecycle.ReconcileResult` is a type that can be used to indicate the result of the reconciliation. 

It can be one of the following:

```go
type ReconcileResult string

const(
	// Success should be returned in case the operator reached its target state
    Success ReconcileResult = "Success"

    // Failed should be returned in case the operator wasn't able to reach its target state and without external changes it's unlikely that this will succeed in the next try
    Failed ReconcileResult = "Failed"

    // Pending should be returned in case the operator is still trying to reach the target state (Requeue, waiting for remote resource to be cleaned up, etc.)
    Pending ReconcileResult = "Pending"
)
```

## Related Decision Records 

Partially supersedes [004 Greenhouse Resource States](004-greenhouse-resource-status-reporting.md)