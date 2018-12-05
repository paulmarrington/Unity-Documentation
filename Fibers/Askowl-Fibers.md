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
A Fiber command does not have an `if` statement, but the same result can be gained with Begin, Break and End.
``` c#
private void Step1(Fiber fiber) {
  if (noMore) fiber.Break();
}
Fiber.Start.Begin.Do(Step1).WaitFor(seconds: 1f).Do(Step2).End.Do(Step3);
```
### Break
Break when called within a Fiber function exits the inner block.
### Exit
When `Exit()` is called from within a Fiber function, the Fiber stack terminates after cleaning up. Mostly used for unexpected conditions or in response to an error.
### Idle and Restart
`Idle` is a built-in emitter listener where `Restart` is the trigger. Restart can be given a reference to the fiber to kick.
``` c#
var idlingFiber = Fiber.Start.Idle.Do(SomethingAfterRestart);
if (moreToDo)  idlingFiber.Restart().Do(SomeMore).Idle;
// ...
if (oneMoreThing)  idlingFiber.Restart().Do(LastAction);
idlingFiber.Restart(); // otherwise fiber will never be released.
```
### SkipFrames
Each command in a Fiber list executes in a separate frame. If you want a short delay, it is efficient to call SkipFrames. The Fiber worker moves to a special queue and only processed when the shortest waiting frame count expires, reducing update ovrhead. The frame rate is usually 30 fps or 60 fps for Unity games.
``` c#
Fiber.Start.Do(Event1).SkipFrames(10).Do(Event2);
```
### Update, LateUpdate and FixedUpdate
By default, Fibers run on `Update()` which occurs once per frame. If `Time.timeScale` is changed then the time between updates changes accordingly. `OnFixedUpdate()` is on a reliable timer so that it is called regularly - more than once per frame if the frame rate is low. `OnLateUpdate()` is called once per frame after `OnUpdate()`. Use it to control a third-person camera so that any character movements are complete.
``` c#
Fiber.Start.OnLateUpdate.Begin.Do(FollowingCamera). Again;
Fiber.Start.OnFixedUpdate.Begin.Do(BlinkMessage).Repeat(10);
Fiber.Start.OnFixedUpdate.OnUpdate.Do(WhyDidIDoThat);
```
### WaitFor(Emitter)
An `Emitter` is an Able class that implements the observer pattern. When used Fibers, they are the key to inter-Fiber synchronisation. By giving external processes emitters, they allow Fibers to wait on asynchronous results.
``` c#
      using (emitter = Askowl.Emitter.Instance) {
        void Fire(Fiber fiber) => emitter.Fire();
        Fiber.Start.WaitFor(emitter).Do(SetEmitterFiredFlag);
        Fiber.Start.WaitRealtime(0.2f).Do(Fire);
      }
```
### WaitFor(IEnumerator)
A C# method with an IEnumerator return value is a state machine with each state transferal happening each update. Use for existing coroutines you would like to integrate. Use sparingly because coroutine state machines use the heap and increase garbage collection.
### Do
Do functions contain project specific logic. Since each `Do` function runs in a single frame, make them short and sweat.
``` c#
Fiber.Start.Do(Breaking).Do(Up).Do(Large).Do(Calculations)
```
### WaitFor(seconds) and WaitRealtime(seconds)

Delay the Fiber for the specified time. `WaitForSeconds` is scaled by `Time.timeScale`, while `WaitForSecondsRealtime` isn't. The Fiber worker is moved to a special queue that is only processed when the shortest waiting frame count expires. This further minimises the processing load during updates. 
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
### Creating a Worker
The only situation I can think of that you may need to resort to writing a new low-level Worker instance would be if you wanted to implement efficient polling, The example below is for `SkipFrames`, but `WaitFor(seconds)` uses a similar approach. The requesting fiber is in a new queue unique to this worker type, inserted in sorted order. Each update needs only to check and process items that are ready to run again.
``` c#
 public static class MyExtensionMethods {
  // So we can make a call like `Fiber.Start.SkipFrames(2);`
  public static Fiber SkipFrames(this Fiber fiber, int framesToSkip) =>
      // The frame is converted from relative to absolute for sorting
      FrameWorker.Instance.Load(fiber: this, data: Time.frameCount + framesToSkip);
}

// Can be private since it is not accessed outside this file
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