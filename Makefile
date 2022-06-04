bindir := bin
clangflags := -O3 -ffreestanding -nodefaultlibs -nostdlib -fno-stack-check -fno-stack-protector -mno-stack-arg-probe -fshort-wchar -mno-red-zone
efiflags := -target x86_64-pc-win32-coff $(clangflags)
kernelflags := $(clangflags)
lldflags := -T kernel.ld -static -Bsymbolic -nostdlib

$(bindir)/kernel.ll: kernel/kernel.fy
	fy com $^ $@

$(bindir)/bootloader.ll: bootloader/bootloader.fy
	fy com $^ $@

$(bindir)/kernel.o: $(bindir)/kernel.ll
	clang $(kernelflags) -c $^ -o $@

$(bindir)/bootloader.obj: $(bindir)/bootloader.ll
	clang $(efiflags) -c $^ -o $@

$(bindir)/bootloader.efi: $(bindir)/bootloader.obj
	lld-link -subsystem:efi_application -nodefaultlib -dll -entry:main $^ -out:$@

$(bindir)/kernel.elf: $(bindir)/kernel.o
	ld.lld $(lldflags) $^ -o $@

zap-font/zap-ext-light18.psf:
	cd zap-font && make zap-ext-light18.psf && cd ..

$(bindir)/font.psf: zap-font/zap-ext-light18.psf
	cp $^ $@

bootloader: $(bindir)/bootloader.efi
kernel: $(bindir)/kernel.elf $(bindir)/font.psf

run: kernel bootloader
	cd $(bindir) && uefi-run bootloader.efi -f kernel.elf -f font.psf && cd ..

clean:
	rm -rf $(bindir)/*