{ pkgs ? import <nixpkgs> { } }:

let unstable = import <unstable> { };

in pkgs.mkShell {
  buildInputs = with pkgs; [ llvm qemu ] ++ (with unstable; [ zig zls ]);

  shellHook = ''
    echo "Zig Development Environment"
    echo "-------------------------"
    echo "Zig version: $(zig version)"
    echo "QEMU version: $(qemu-system-arm --version | head -n 1)"
    echo "-------------------------"
  '';
}

