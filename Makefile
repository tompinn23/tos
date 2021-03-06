arch ?= x86_64
kernel := build/kernel.elf
iso := build/os-$(arch).iso
target ?= $(arch)-tos
rust_lib := target/$(target)/debug/libtos.a

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

.PHONY: all clean run iso kernel gdb

all: $(kernel)

clean:
	@rm -r build

run: $(iso)
	@qemu-system-x86_64.exe -cdrom $(iso) -s

debug: $(iso)
	@qemu-system-x86_64.exe -cdrom $(iso) -s -S

gdb:
	@rust-gdb "build/kernel.elf" -ex "target remote :1234"	

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.elf
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): kernel $(rust_lib) $(assembly_object_files) $(linker_script)
	@ld -n --gc-sections -T $(linker_script) -o $(kernel) $(assembly_object_files) $(rust_lib)

# compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
	
kernel:
	@RUST_TARGET_PATH=$(shell pwd) xargo build --target $(target)
