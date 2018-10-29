# Able Integrity Testing

To use Able you need do no more than load the package from the Unity Asset store. A few more actions are required to run the integrity tests. By default, tests usually are only enabled for the parent project so as not to mess up client projects.

First, open the scene Askowl-Able-Examples, open build settings then press the *Add Open Scenes* button.

Next, open *Player Settings* and append *;Able;AskowlAble* to the definitions. Able adds these automatically in the *Able* project. The project you are creating has an entry also.

Save your project. Note that *Askowl* has now been appended to the defines.

Ask ***Unity*** to reimport all assets to account for the new defines.

Now you can run the *Edit* and *Run* mode tests.
