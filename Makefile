clangflags := -ffreestanding -nodefaultlibs -nostdlib -fno-stack-check -fno-stack-protector -mno-stack-arg-probe -fshort-wchar -mno-red-zone -static
efiflags := -O3 -target x86_64-pc-win32-coff $(clangflags)
kernelflags := -O3 $(clangflags)
lldflags := -T kernel.ld -static -Bsymbolic -nostdlib

bin/kernel.ll: kernel/**/*.fy kernel/*.fy
	fy com kernel/kernel.fy $@

bin/bootloader.ll: bootloader/**/*.fy bootloader/*.fy
	fy com bootloader/bootloader.fy $@

bin/kernel.o: bin/kernel.ll
	clang $(kernelflags) -c $^ -o $@
	@if [ -n "${DEBUG}" ]; then								\
		clang $(kernelflags) -c $^ -o $@.S -S;				\
		clang $(kernelflags) -c $^ -o $@.ll -S -emit-llvm;	\
	fi

bin/bootloader.obj: bin/bootloader.ll
	clang $(efiflags) -c $^ -o $@

bin/bootloader.efi: bin/bootloader.obj
	lld-link -subsystem:efi_application -nodefaultlib -dll -entry:main $^ -out:$@

bin/kernel.elf: bin/kernel.o
	ld.lld $(lldflags) $^ -o $@

zap-font/zap-ext-light20.psf:
	cd zap-font && make zap-ext-light20.psf && cd ..

bin/font.psf: zap-font/zap-ext-light20.psf
	cp $^ $@

bootloader: bin/bootloader.efi
kernel: bin/kernel.elf bin/font.psf
build: kernel bootloader

run: build
	cd bin && uefi-run bootloader.efi -f kernel.elf -f font.psf -- -m 512M && cd ..

clean:
	rm -rf bin/*