set -e
fy com ./kernel/kernel.fy ./bin/kernel.ll
# make bin/kernel.efi
clang -target x86_64-pc-win32-coff -fno-stack-protector -fshort-wchar -mno-red-zone -c ./bin/kernel.ll -o ./bin/kernel.obj -O3
lld-link -subsystem:efi_application -nodefaultlib -dll -entry:main ./bin/kernel.obj -out:./bin/kernel.efi
# run with uefi-run
uefi-run ./bin/kernel.efi