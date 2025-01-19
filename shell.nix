{ pkgs ? import <nixpkgs> { } }:

let unstable = import <unstable> {};

in pkgs.mkShell {
  buildInputs = with pkgs; [
    unstable.zig
    llvm
    qemu
  ];

  shellHook = ''
    echo "Zig Development Environment"
    echo "-------------------------"
    echo "Zig version: $(zig version)"
    echo "QEMU version: $(qemu-system-arm --version | head -n 1)"
    echo "-------------------------"
  '';
}

