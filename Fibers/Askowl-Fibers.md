---
title: Askowl Fibers for Unity3D
description: Like Coroutines but reduced overhead
---
* Table of Contents
{:toc}
Download from the [Unity Store](https://assetstore.unity.com/packages/slug/133094)

# [Executive Summary](http://www.askowl.net/unity-fibers)

Coroutines are the core mechanism in Unity3d MonoBehaviour classes to provide independent processing as a form of co-operative multi-tasking. Activities that must occur in order use `yield return myCoroutine();` to wait on completion before continuing. Yield instructions must reside in methods that have an IEnumerator return type. C# turns them into a state machine. These state machines are not resettable, so they must be discarded once complete. Since every call generates a new state machine, this puts a heavy load on the garbage collector. Using coroutines in abundance can cause glitches in the running of VR and mobile applications.

***Fibers*** provides an alternative co-operative multi-tasking approach to Coroutines with less overhead. It is not a drop-in replacement but is intended for heavy usage situations.

On another subject, some unity packages, specifically FireBase, use C# 4+ Tasks, a preemptive multitasking interface. Anything using Task callbacks must be treated as independent threads with semaphores and the like to protect against data corruption. The Askowl Tasks class mergest tasks into Fibers so that they fit better and more safely into the Unity system.

> Read the code in the Examples Folder and run the Example scene.
>
> The Doxygen pages [here](https://paulmarrington.github.io/Unity-Documentation/Fibers/Doxygen/html/annotated.html)



# The Structure of a Fiber Operation

A Fiber is typically a single statement where each composite function or method runs in a new frame.

``` c#
private void CheckForDeath(Fiber fiber) {
  if (IsDead()) {
    StartDeathAnimation(); // another Fiber
    fiber.Break(); // stop any hit animation
  }
}
private void Stagger(Fiber fiber) {/*Trigger stagger animation*/}
private void Stars(Fiber fiber) {/*Trigger stars over head animation*/}
// ...
Fiber.Start
  .Do(Stagger).WaitFor(seconds: 0.2f)
  .Begin.Do(Stars).WaitFor(seconds: 0.2f).Do(CheckForDeath).Repeat(5);
```
Note that each step in a fiber is passed a reference. This is mostly so that you can call `fiber.Break()` if needed.

Once a Fiber terminates it is placed in a recycle bin for later reuse. The section below includes functions that allow loops, repeats and conditional exits.

## Built-in Fiber Commands
### AsCoroutine
Place at the end of a Fiber command to integrate Fibers into traditional coroutines.
``` c#
    private void Flasher(Fiber fiber) {/*...*/}
    private void Banger(Fiber fiber) {/*...*/}
    public IEnumerator Flash() {
      yield return Fiber.Start.Do(Flasher)
                        .WaitFor(seconds: 0.6f).Do(Banger).AsCoroutine();
    }
```
### Begin Again
Everything between Begin and Again runs over and over indefinitely. Call Break() in one of your functions to abort looping. Unlike coroutines, Fibers don't terminate when a component is disabled or the scene changes. Explicitly terminate Fibers by keeping a reference and calling Exit().
``` c#
Fiber swayFiber;
void OnEnable() {
  swayFiber = Fiber.Start.Begin.Do(Sway).WaitFor(seconds: 0.4f).Again;
}
void OnDisable() {
  swayFiber.Exit();
}
```
### Begin Repeat
A Fiber can have a repeat count. It could be the number of sparkler flashes or the number of times we warn a player of a danger. You can exit the loop prematurely with Break or Exit.
``` c#
Fiber.Start.Begin.Do(ShowLightBulb).WaitForSeconds(3).Repeat(5);
```
### Begin End
Use `Break()` from inside any Do-code to go to the next command after `End`*[]:

``` c#
private void Step1(Fiber fiber) {
  if (noMore) fiber.Break();
}
Fiber.Start.Begin.Do(Step1).WaitFor(seconds: 1f).Do(Step2).End.Do(Step3);
```

### Begin Until
`Begin`/`Until` is another looping function terminated with a boolean test at the end of each cycle.
``` c#
Fiber mineAlert = Fiber.Instance.Begin.WaitFor(flashAlarmLight)
                       .Until(_ => MineDistance() > 1.0f);
```

### Break
Break when called within a Fiber function exits the inner block.

### BreakIf
`BreakIf` does what it says. Break out of the inner block if a function with a boolean return returns true.

```c#
counter         = 0;
var fiber = Fiber.Start.Begin.Do(_ => counter++).BreakIf(_ => counter > 5).Again;
```

### Do
Do functions contain project specific logic. Since each `Do` function runs in a single frame, make them short and sweat.
``` c#
Fiber.Start.Do(Breaking).Do(Up).Do(Large).Do(Calculations)
```

### Exit
When `Exit()` is called from within a Fiber function, the Fiber stack terminates after cleaning up. Mostly used for unexpected conditions or in response to an error.

``` c#
Fiber.Start.WaitFor(seconds: 2).Exit(otherFiber)
```

### Fire

Fire an emitter in a way that fits into a fiber stream.

``` c#
Fiber.Start.Begin.WaitFor(seconds: 5.0f).Fire(FiveSecondWarningEmitter).Again;
```


### Go
Unless you dispose of a fiber, it lives on for as long as you keep at least one reference. `Go` restarts a fiber from the first action even if it is not running. Use `Exit` if you want to terminate an earlier run first.

``` c#
var ping = Fiber.Start.Do(_ => Ping()).WaitFor(seconds: 1.0f);
// ...
if (sonar) ping.Go();
```

### Finish
`Finish` is the quintessential do-nothing function. Using `Start` turns creating a Fiber into a statement. If you don't need a reference, the statement is not an assignment. Such a statement must end in a function call to pass the C# compiler.

``` c#
Fiber.Start.Begin.Do(_ => Something()).Again.Finish();
```
### If // Else // Then
This most common example of program logic needs little explanation.

```c#
var fiber1 = Fiber.Instance
                 .If(_ => mark == 1).Do(_ => mark = 2).Then;
// or...
var fiber2 = Fiber.Instance
                 .If(_ => mark == 1).Do(_ => mark = 2)
                 .Else.Do(_ => mark = 3).Then;
```

### Instance
`Instance` allows a fiber to be compiled to be run later with `Go()`, `WaitFor(Fiber)` or `AsCoroutine()`. Precompilation is good since all functions provided as parameters to `Do()`, `WaitFor()` and others compile to an anonymous class instantiated on creation. By function, I mean lambdas, inner functions or references to members of an existing class.

So, the **only** way to take the load from the garbage collector is to precompile fibers and reuse them. It does not apply to infinite loops since they only ever have one instance.

```c#
Fiber change;
float changeAmount, changeInterval;
int changeSteps;

void Awake {
  // No Need to precompile since the loop is infinite
  void trickleCharge(Fiber fiber) => health.Value += trickleChargePerSecond;
  Fiber.Start.Begin.WaitFor(seconds: 1.0f).Do(trickleCharge).Again.Finish();
  change = Fiber.Instance.Begin
                .Do(_ => health.Value += changeAmount)
                .WaitFor(_ => changeInterval)
                .Repeat(_ => changeSteps);
}

void ChangeHealth(float amount, float every, int over) {
  changeAmount = amount;
  changeInterval = every;
  changeSteps = over;
  change.Go();
}
```

For a complete implementation, look at the source to `ChangeOverTime` in this package.

There is one trip-up for new players that I want to point out. Note `WaitFor(_ => changeInterval)` is a function rather than just a float reference. If we had said `WaitFor(changeInterval)` instead, the waiting time would have been zero since `ChangeInterval` was zero at the time of compile.

Since all functions are compile-time generated, the steps are quite efficient when run.

### SkipFrames
Each command in a Fiber list executes in a separate frame. If you want a short delay, it is efficient to call SkipFrames. The Fiber worker moves to a special queue and only processed when the shortest waiting frame count expires, reducing update overhead. The frame rate is usually 30 fps or 60 fps for Unity games.
``` c#
Fiber.Start.Do(Event1).SkipFrames(10).Do(Event2);
```
### Timeout
Asynchronous processes suffer from services that never take the next step. External interfaces that don't return, unpressed buttons, you get the idea. By adding `Timeout(seconds: 1.5f)` or the like and a fiber will at least exit reasonable gracefully.

### Update, LateUpdate and FixedUpdate
By default, Fibers run on `Update()` which occurs once per frame. If `Time.timeScale` is changed then the time between updates changes accordingly. `OnFixedUpdate()` is on a reliable timer and hence called regularly - more than once per frame if the frame rate is low. `OnLateUpdate()` is called once per frame after `OnUpdate()`. Use it to control a third-person camera so that any character movements are complete.
``` c#
Fiber.Start.OnLateUpdate.Begin.Do(FollowingCamera). Again;
Fiber.Start.OnFixedUpdate.Begin.Do(BlinkMessage).Repeat(10);
Fiber.Start.OnFixedUpdate.OnUpdate.Do(WhyDidIDoThat);
```
### WaitFor
The main reason for Fibers, Coroutines and Threads is that most tasks spend much more time waiting for something than actually doing anything. Enter `WaitFor` to the rescue. Most `WaitFor` commands come in two flavours - to provide the source directly or by calling a function. There is a method to this madness. If the resource is unavailable or likely to change in the Fiber compile phase, then the function approach must be used. Examples would include an emitter not yet have created or seconds that could change between fiber runs.

The `WaitFor` commands here provide all basic usage. `WaitFor(Emitter)` can be used for almost any other case you require.

#### WaitFor(Emitter) and WaitFor((fiber) => emitter)
When used with Fibers, emitters are the key to inter-Fiber synchronisation. By giving external processes emitters, they allow Fibers to wait on asynchronous results.
``` c#
      using (emitter = Askowl.Emitter.Instance) {
        void Fire(Fiber fiber) => emitter.Fire();
        Fiber.Start.WaitFor(emitter).Do(SetEmitterFiredFlag);
        Fiber.Start.WaitRealtime(0.2f).Do(Fire);
      }
```
#### WaitFor(Fiber) or WaitFor((fiber) => anotherFiber)
Waiting for another Fiber is a way of factoring out common sequences. The driving fiber continues once the fiber being waited on completes. If the inner fiber is not running, `Go` is called.

```c#
// Create and display a thingamebob
Fiber display = Fiber.Instance.Do(_ => whatever);
// Wait for the thingamebob to finish doing it's thing
Fiber completion = Fiber.Instance.If(display.Running)
                        .WaitFor(display.OnComplete).Then;
// Allow current thingamebob to complete before starting another
Fiber nextDisplay = Fiber.Instance.WaitFor(completion)
                         .Do(_ => SetNextDisplay).WaitFor(display);
// Let thingamebob to complete before falling over
Fiber fallOver = Fiber.Instance.WaitFor(Completion).Do(_ => FallOver();
// ...
display.Go();
// ...
if (fellOver) fallOver.Go() else nextDisplay.Go();
```

An admittedly theoretical example follows the dance of four fibers. Note that we don't need to start the completion fiber.

#### WaitFor(IEnumerator) or WaitFor((fiber) => iEnumerator)
A C# method with an IEnumerator return value is a state machine with each state transferal happening each update. Use for existing coroutines you would like to integrate. Use sparingly because coroutine state machines use the heap and increase garbage collection.

#### WaitFor(seconds), WaitFor((fiber) => seconds), WaitRealtime(seconds) and WaitRealtime((fiber) => seconds)
Delay the Fiber for the specified time. `WaitForSeconds` is scaled by `Time.timeScale`, while `WaitForSecondsRealtime` isn't. The Fiber worker moves to a special queue and only processed when the shortest waiting frame count expires. It further minimises the processing load during updates.

#### Waitfor(Task)
C# and .NET Core provide support for Tasks - a preemptive thread-based multi-tasking approach. `Task` works fine with Unity except that a response happens at any time, not just in one of the update cycles. Attempting to do any Unity between frames is disastrous. Using this action within a Fiber synchronises to Update, LateUpdate or FixedUpdate as you require.
## Creating New Fiber Commands
You should only need to create new Fiber commands when dealing with external asynchronous events.
### Using an Emitter
The simplest and most common extension methods use an emitter to synchronise with an outside event.
``` c#
  public static class MyExtensionMethods {
    public static Fiber WaitFor(this Fiber fiber, Task task) {
      var emitter = Emitter.Instance;

      void action(Task _) {
        emitter.Fire();
        emitter.Dispose();
      }

      task.ContinueWith(action);
      return fiber.WaitFor(emitter);
    }
  }
// ...
 Fiber.Start.WaitFor(task).Do(Whatever);
```
### CancelOn
Tell a fiber to exit if an emitter fires.
``` c#
Fiber fiber = Fiber.Instance.CancelOn(canceller).Begin.Do(something).Again;
// ...
calceller.Fire();
```

### Context

If we run fiber in a class scope, we can keep context in the class. When it runs longer than the calling scope, we need to have the fiber know some more about the context. To this end, we can set it during the fiber execution and access it whenever we have a reference to the fiber.

``` c#
    private class FiberContext : IDisposable {
      public int  Number;
      public void Dispose() => Number = 0;
    }

    [UnityTest] public IEnumerator Context() {
      var fiberContext = new FiberContext {Number = 12};
      Fiber.Start.Context(fiberContext).WaitFor(seconds: 0.1f).Do(
        fiber => {
          var context = fiber.Context<FiberContext>();
          Assert.AreEqual(12, context.Number);
        });
      // `Start` disposes of fiber after running it
      yield return new WaitForSeconds(0.2f);
      // proving that the context is also disposed
      Assert.AreEqual(0, fiberContext.Number);
    }
  }
```

If a new context replaces the old, the former is disposed of first.


### Creating a Worker
The only situation I can think of that you may need to resort to writing a new low-level Worker instance would be if you wanted to implement efficient polling, The example below is for `SkipFrames`, but `WaitFor(seconds)` uses a similar approach. The requesting fiber is in a new queue unique to this worker type, inserted in sorted order. Each update needs only to check and process items that are ready to run again.
``` c#
 public static class MyExtensionMethods {
  // So we can make a call like `Fiber.Start.SkipFrames(2);`
  public static Fiber SkipFrames(this Fiber fiber, int framesToSkip) =>
      // The frame is converted from relative to absolute for sorting
      FrameWorker.Instance.Load(fiber: this, data: Time.frameCount + framesToSkip);
}

private class FrameWorker : Worker<int> {
  // Workers are all cached
  public static      FrameWorker Instance  => Cache<FrameWorker>.Instance;
    
  // and must be sent back to cache when done with
  protected override void Recycle() { Cache<FrameWorker>.Dispose(this); }
    
  // comparison is essential to efficient polling
  protected override int CompareTo(Worker other) =>
      Seed.CompareTo((other as FrameWorker)?.Seed);
    
  // worker processes entries until `NoMore` returns true
  public override bool NoMore => Seed >= Time.frameCount;
    
  // We only have one step, so we can recycle immediately once done
  public override void Step() { Dispose(); }
    
  // more complex instantiation may require more preparation to convert for sorting
  // See the source SecondsWorker.cs for an example. Returning false will abort the
  // current operation
  protected override boolean Prepare() { return true; }
}
```
## Debugging
Set that static boolean `Fiber.Debugging` to get console output whenever a `Do()` action is called and whenever a new action is set. The output displays while running in the Unity Editor

Asynchronous programming is always harder to follow. If you keep a handle to a Fiber, you can use `ToString()`. It lists out all the actions in the Fiber with square brackets around the one currently being processed. It appends you the current worker and queue.

## Emitter

A consumer creates an ***Emitter***. Many producers can register and send events. Listeners get told when anyone who has access to the emitter instance pulls the trigger.

```c#
var emitter = new Emitter();
// ...
emitter.Listen(incrementCounter);
// ...
emitter.Fire;
// ...
private static readonly Emitter.Action incrementCounter = _ => {
  counter++;
  return true;
};
```

Building a delegate creates an anonymous class. Create it once, either as a static field or in the constructor.

When you no longer need the listener `return false` and it removes itself.

```c#
var emitter = new Emitter();
// ...
private Emitter.Action incrementCounter;
// ...
if (incrementCounter == default) {
  incrementCounter = _ => {
    counter++;
    return true;
  };
}
emitter.Listen(incrementCounter);
// ...
emitter.Fire;
```

### Emitter.Action
`Emitter.Action` is the delegate used as the `Emitter.Listen` parameter. It gets a copy of the emitter (and any context) and returns true normally or false to remove the listener from the listening queue.

### Emitter.Context
If we respond to an emitter from a class scope, we can keep context in the class. When it is at the function scope, we need to have the emitter know some more about the context.

``` c#
    private class EmitterContext : IDisposable {
      public int  Number;
      public void Dispose() => Number = 0;
    }

    [Test] public void Context() {
      var emitterContext = new EmitterContext {Number = 12};
      using (emitter = new Emitter().Context(emitterContext)) {
        emitter.Subscribe(em => Assert.AreEqual(12, em.Context<EmitterContext>().Number));
        emitter.Fire();
        Assert.AreEqual(12, emitter.Context<EmitterContext>().Number);
      }
      // proving that the context is also disposed
      Assert.AreEqual(0, emitter.Context<EmitterContext>().Number);
    }
```

 `Emitter.Dispose()' calls dispose on the context if and only if the context is `IDisposable`.

### Emitter.Firings
An emitter keeps a count of the number of times it has been fired. It is particularly useful to check if an emitter has fired before a listener has been attacked.

### Emitter.Remove
If you still have a reference to the listener you used you can remove it again. alternatively you can remove from inside the listener with `emitter.
StopListening()`;

``` c#
Emitter.Action removeMyself = emitter => {
  counter++;
  emitter.StopListening();
}
using (emitter = Emitter.Instance.Listen(incrementCounter).Listen(removeMyself)) {
  emitter.Remove(incrementCounter);
  emitter.Fire();
  Assert.AreEqual(expected: 1, actual: counter);
  emitter.Fire();
  Assert.AreEqual(expected: 1, actual: counter);
}
```


### Emitter.RemoveAllListeners
Does as it says.

### SingleFireInstance
I find that in most cases I get an emitter from the cache, wait for one firing then dispose of it. Because this is an asynchronous process, it is messy. It is better for the emitter to dispose of itself.

### Emitter.StopListening
This method is meant to be called inside a listener. The current or most recently accessed listener will be removed from the firing line.

### Emitter.Waiting
Returns true if an emitter has one or more listeners registered.

## DelayedCache
I have come across circumstances involving fibers where the ordinary Able cache is too limited. Consider an external service where the results are held in a cached data object. If the service call releases it then can be reused before client code runs on the next frame. A `DelayedCache` object does not return a DTO to the cache until after an interval has passed. The default is 10 frames, but it can be adjusted as needed.

``` c#
  public class Example {
    private class DTO : DelayedCache<DTO> {
      public int Number;
      // ...
    }

    [UnityTest] public IEnumerator DelayedCacheTest() {
      var data = DelayedCachedData.Instance;
      data.Frames = 10;
      data.Number = 11;
      // ...
      data.Dispose();
      // client has 10 frames to process or take a copy of the data.
    }
  }
```
