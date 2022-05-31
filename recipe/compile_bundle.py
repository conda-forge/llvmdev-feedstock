from pathlib import Path
import ast
import astor
import os
import shutil


BAZEL_DIR = Path("utils") / "bazel"
BAZEL_OUT = BAZEL_DIR / "bazel-bin" / "external" / "llvm-project"
LIB_TARGET_DIR = Path(os.environ["PREFIX"]) / "lib"
OTHER_TARGET_DIR = Path(os.environ["PREFIX"]) / "share" / "llvm_for_tf"


def extend_linkopts(kw, name):
    current_src = astor.to_source(kw.value)[:-1]
    return ast.parse(f"{current_src} + ['-l{name}']").body[0]


def new_kwarg(name, code):
    return ast.keyword(arg="linkopts", value=ast.parse(code).body[0].value)


def rewrite_binaries(code, symbol):
    sym = symbol.lower()
    tree = ast.parse(code)
    for node in ast.walk(tree):
        # Find all function calls
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
            if node.value.func.id == "cc_library":
                # Determine the name of the library
                name = linkopts = None
                for kw in node.value.keywords:
                    if kw.arg == "name":
                        name = kw.value.value
                    elif kw.arg == "linkopts":
                        linkopts = kw

                # Remove srcs
                node.value.keywords = [kw for kw in node.value.keywords if kw.arg != "srcs"]

                # Add the compiled library via linkopts
                expected_lib = BAZEL_OUT / sym / f"lib{name}.a"
                if expected_lib.exists():
                    libname = f"{symbol}TF{name}"
                    if linkopts is None:
                        node.value.keywords.append(new_kwarg("linkopts", f"['-l{libname}']"))
                    else:
                        extend_linkopts(linkopts, libname)
                    # Move the compiled library into the target folder
                    shutil.copyfile(
                        expected_lib,
                        LIB_TARGET_DIR / f"lib{libname}.a"
                    )
            elif node.value.func.id == "cc_binary":
                # TODO: Implement this
                pass
    return astor.to_source(tree)


llvm_build = (BAZEL_DIR / "llvm-project-overlay" / "llvm" / "BUILD.bazel").read_text()
mlir_build = (BAZEL_DIR / "llvm-project-overlay" / "mlir" / "BUILD.bazel").read_text()
bzl = rewrite_binaries(llvm_build, "LLVM")
(BAZEL_DIR / "llvm-project-overlay" / "llvm" / "BUILD.bazel").write_text(bzl)
bzl = rewrite_binaries(mlir_build, "MLIR")
(BAZEL_DIR / "llvm-project-overlay" / "mlir" / "BUILD.bazel").write_text(bzl)
