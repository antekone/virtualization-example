# Apple's Virtualization Framework Example

This is a minimal example on how to use Apple's `Virtualization.framework`.

Please see at least the "Configuring" section before using it.

# Building on macOS

Only building on macOS is supported, for obvious reasons -- there is no 
`Virtualization.framework` on other platforms.

In order to build the project, checkout the sources first:

    $ git clone git@github.com:antekone/virtualization-example

Configure it using CMake:

    $ cmake -Bbuild

And build it:

    $ cmake --build build -j

# Running

The build process should produce an app bundle binary `build/Bundle.app`,
which should be digitally signed with an adhoc codesigning key. The app
bundle should be ready to be executed right away:

    ./build/Bundle.app/Contents/MacOS/Bundle

(or doubleclick it on Finder)

# Configuring

## Hardcoded path to VM.bundle needs to be changed

You will need to modify the source code in order to use this. By default,
the sources hardcode the VM to be executed to `/Volumes/SSD/VM.bundle`, which
is most probably not what you want. You need to provide an absolute path to
your `VM.bundle`, which may reside inside your home directory, or on your
external hard disk.

My MacMini has only 256GB drive, and I don't want to waste it for big VMs.
I've found out that using an external SSD drive works pretty well, that's why
I've defaulted the example to my scenario :)

## If you want to boot to recovery OS, you need to modify a flag

If you would want to boot into RecoveryOS (e.g. to disable System Integrity
Protection), you need to modify this flag in `main.mm`:

            opts.bootMacOSRecovery = FALSE;

Change it to TRUE, recompile, run the VM, enter recovery mode. After you're
done, turn of the VM, change the flag back to FALSE, recompile, and run the
VM.

# Contact

This repository is a companion repository for the blog post on my blog:

https://anadoxin.org/blog

Have fun ;)