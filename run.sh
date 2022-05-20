set -e
fy com ./kernel/kernel.fy ./bin/kernel.ll
# make bin/kernel.efi
clang -target x86_64-pc-win32-coff -O3 -ffreestanding -fno-stack-check -fno-stack-protector -mno-stack-arg-probe -fshort-wchar -mno-red-zone -c ./bin/kernel.ll -o ./bin/kernel.obj
lld-link -subsystem:efi_application -nodefaultlib -dll -entry:main ./bin/kernel.obj -out:./bin/kernel.efi
# run with uefi-run
uefi-run ./bin/kernel.efi