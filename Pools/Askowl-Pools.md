---
title: Askowl Pools for Unity3D
description: Pooling GameObjects for Higher Performance
---

# [Pooling](http://www.askowl.net/unity-pools)
Download from the [Unity Store](https://assetstore.unity.com/packages/slug/134704)

* * Table of Contents
{:toc}

## Executive Summary

When pooling is mentioned in the same sentence as Unity, it refers to pooling game objects for reuse. Some Unity game objects are ephemeral, being rapidly created and destroyed for visual effect. Examples include raindrops, meteors, projectiles, birds and smoke from a fire. Continually instantiating and destroying hundreds or even thousands of the same game object is processing intensive for both Unity and the garbage collector. In most cases, only a limited number are in play at any one time. We can reuse game objects to avoid the creation and destruction cycle we can reuse game objects. We are trading memory usage for CPU load. Memory is the more abundant resource, even on mobile devices.

> Read the code in the Examples Folder and run the Example scene
> The Doxygen pages are [here](https://paulmarrington.github.io/Unity-Documentation/Pools/Doxygen/html/annotated.html)

## Introduction
Unity3D games can run on lightweight platforms such as phones, tablets and consoles. Virtual or augmented reality games are immersive, and the least stutter in frame-rate is bright and annoying. Two of the most prominent culprits during gameplay are instantiating many complex objects and garbage collection.

`Instantiate()` and `Destroy()` aren't evil, but using them has a significant impact on performance. The solution is to use a pool of these objects. It minimises expensive instantiation, and the garbage collector does not have to reclaim the memory for every usage.

## Asset Pooling

A GameObject becomes a pool if it has the `Pool` script attached. Any child object becomes candidates for pooling. The Askowl Pools package creates a default pool once installed. You can have as many pools as you wish and they may live in any scene. The names have to be unique.

<img src="PoolInScene.png" width="50%">

In this example, three GameObjects have become pooling aware. ***Scene GameObject*** is in the scene, while the other two copies of the same prefab with differing values in inspector-available fields. They represent two different characters or effects that differ.

To retrieve a clone from the pool, use `Acquire()` with the path or the name of the game object or prefab.

1. For a game object in the scene, the path can be sparse, but it must be unique. The original moves to the pool, but clones are added to the original game object parent when they are activated.
2. If a prefab is in a ***Resources*** directory, then the path must be complete and relative to that directory. The prefab does not need to be in the scene as it loads on demand.
3. Prefabs not in a ***Resources*** directory must be in a scene.

Cloning of a new GameObject from the master occurs if the pool is empty.

```c#
var spark = Pool.Acquire<SparkDriver>("prefabs/spark");
// or to retrieve the GameObject (analagous to spark.gameObject)
var sparkGameObject = Pool.Acquire("prefabs/spark");
```

To release an object back to the pool, disable it. Normally an ephemeral game object deactivates itself once it knows it is no longer needed.

```c#
SetActive(false);
```
Do not call `Destroy()` unless you don't want to reuse the GameObject. A destroyed object does not return to the pool.

### Acquire GameObject by Name
Calling `Acquire` with the name of the GameObject retrieves a clone from the pool, instantiating a new one. `Pool.Acquire("Scene GameObject")` does the trick, or returns null if the Pool did not contain an original by that name.

Seeding some of the GameObject information using optional parameters is possible.

### Transform parent
A visual effect has the target as the parent, while a character may have a spawn point or a team leader. Position and rotation below are relative to that of the parent.

### Vector3  position
The location where the clone spawns relative to the parent. It defaults to (0, 0, 0).

### Quaternion rotation
The facing direction, relative to the parent.

### bool enable
Defaults to true to enable the clone when taken from the pool or created.

### bool poolOnDisable
PoolOnDisable also defaults to true. Using `SetActive(false)` to disable a component causes it to return to the pool. To enable and disable and as part of game processing, set `poolOnDisable` to false. Use `Pool.Return(clone)` to release the GameObject to the pool for reuse.

```C#
    for (int i = 0; i < 21; i++) {
      prefab1[i] =
        Pool.Acquire<PoolPrefabScriptSample>("PoolSamplePrefab",
                                             parent: FindObjectOfType<Canvas>().transform,
                                             position: new Vector3(x: i * 60, y: i * 60));
    }
```

### Acquire GameObject by Type
The generic form of `Acquire` is a shortcut to get a component.
```C#
PoolPrefabScriptSample script = Pool.Asquire<PoolPrefabScriptSample>();
// is the same as
script = Pool.Asquire<PoolPrefabScriptSample>("PoolPrefabScriptSample");
// is the same as
GameObject clone = Acquire(typeof(T).Name);
script = (clone == null) ? null : clone.GetComponent<T>();
```
The same optional parameters are available as the non-generic game object, adding name so you can return a prefab with a different name to the MonoBehaviour inside.

### PoolFor
Only in testing is it necessary to retrieve an item from a pool. 
Provide the string name of the master GameObject used to create the pool. The instance returns are of `PoolQueue` and provide two public interfaces.

1. public GameObject Master;
1. public GameObject Fetch();

Since `PoolQueue` is a  `Fifo` class, it inherits all those access and processing methods and fields.
