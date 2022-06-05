bindir := bin
clangflags := -ffreestanding -nodefaultlibs -nostdlib -fno-stack-check -fno-stack-protector -mno-stack-arg-probe -fshort-wchar -mno-red-zone -static
efiflags := -O3 -target x86_64-pc-win32-coff $(clangflags)
kernelflags := -O3 $(clangflags)
lldflags := -T kernel.ld -static -Bsymbolic -nostdlib

$(bindir)/kernel.ll: kernel/*.fy
	fy com kernel/kernel.fy $@

$(bindir)/bootloader.ll: bootloader/**/*.fy bootloader/*.fy
	fy com bootloader/bootloader.fy $@

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
build: kernel bootloader

run: build
	cd $(bindir) && uefi-run bootloader.efi -f kernel.elf -f font.psf && cd ..

clean:
	rm -rf $(bindir)/*