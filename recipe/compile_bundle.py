from pathlib import Path
import ast
import astor
import os
import shutil

BAZEL_DIR = Path("utils") / "bazel"
BAZEL_OUT = BAZEL_DIR / "bazel-bin" / "external" / "llvm-project"
LIB_TARGET_DIR = Path(os.environ["PREFIX"]) / "lib" / "llvm_for_tf"
OTHER_TARGET_DIR = Path(os.environ["PREFIX"]) / "share" / "llvm_for_tf"

llvm_build = (BAZEL_DIR / "llvm-project-overlay" / "llvm" / "BUILD.bazel").read_text()
tree = ast.parse(llvm_build)
for node in ast.walk(tree):
    # Find all function calls
    if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
        if node.value.func.id == "cc_library":
            # Determine the name of the library
            name = None
            for kw in node.value.keywords:
                if kw.arg == "name":
                    name = kw.value.value
            expected_lib = BAZEL_OUT / "llvm" / f"lib{name}.a"
            if expected_lib.exists():
                # Remove srcs
                node.value.keywords = [kw for kw in node.value.keywords if kw.arg != "srcs"]
                # Add the compiled library via linkopts
                node.value.keywords.append(ast.keyword(arg="linkopts", value=ast.parse(f"['-lLLVMTF{name}']").body[0].value))
                # Move the compiled library into the target folder
                shutil.copyfile(
                    expected_lib,
                    LIB_TARGET_DIR / f"libLLVMTF{name}.a"
                )
        elif node.value.func.id == "cc_binary":
            # TODO: Implement this
            pass

(OTHER_TARGET_DIR / "llvm" / "BUILD.bazel").write_text(astor.to_source(tree))
