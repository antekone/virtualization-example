# Apple's Virtualization Framework Example

This is a minimal example on how to use Apple's `Virtualization.framework`. It
supports booting the guest VM into recovery mode to disable SIP in the guest
macOS.

It was tested on macOS 12. Because it uses some undocumented features, it may
not work on macOS 13, where the API changes a little bit. Use at your own risk.
Backup your existing VMs before use.

Please see at least the "Configuring" section before using it.

# Building on macOS

Only building on macOS is supported, for obvious reasons -- there is no 
`Virtualization.framework` on other platforms.

In order to build the project, checkout the sources first (don't use spaces in directories -- if you do, the build scripts will break):

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

(or doubleclick it in Finder)

You will need to have a VM.bundle virtual machine created first. In order
to create a VM.bundle virtual machine, you need to obtain the InstallationTool
from Apple's original example code.

Just head on to [this link][1] and follow the instructions. After building
the official example code, you will have a binary tool called InstallationTool.
Run it, and it will download a fresh "restore image" file from Apple's servers, 
from which it will automatically install macOS guest. It will create 
`$HOME/VM.bundle` file with macOS system installed. Then, you can use the 
tool from this repository to run the `VM.bundle` VM.

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

The code from this repository uses an undocumented method of enabling the
"boot to recovery OS" flag. It works on macOS 12.

Framework version installed with macOS 13 has a different method of enabling
the recovery OS, which is documented. This tool inside this repository doesn't
support it yet. But the documented method is easy to implement yourself, it
needs changing just a few lines :).

# Contact

This repository is a companion repository for the future blog post on my blog:

https://anadoxin.org/blog

Have fun ;)

[1]: https://developer.apple.com/documentation/virtualization/running_macos_in_a_virtual_machine_on_apple_silicon_macs?language=objc