#!/usr/bin/env python3
"""
Script to generate the patch files needed by ROOT for clang. It is based on the
upstream LLVM tag and the ROOT tag of the current build. The latter is then used
to retrieve the tag of the ROOT LLVM fork which contains the needed patches.

Once the patches have been generated, the following can be used to add them to
the meta.yaml file. To be used within the patches/root directory.

print("\n".join([f'      - patches/root/{name}' for name in sorted(os.listdir())]))
"""

import glob
import os
import shlex
import shutil
import subprocess
import re
from contextlib import contextmanager
from pathlib import Path

THIS_DIR = Path(__file__).parent.resolve()


@contextmanager
def change_directory(path: str):
    """Change to 'path' directory and restore it when done."""
    old_dir = os.getcwd()
    try:
        os.chdir(path)
        yield
    finally:
        os.chdir(old_dir)


def retrieve_root_llvm_fork_tag(root_tag) -> str:
    """
    Retrieve the correct tag for the
    llvm-project fork used by the ROOT build.
    """
    tag = f"https://raw.githubusercontent.com/root-project/root/{root_tag}/interpreter/llvm-project/llvm-project.tag"
    cmd = shlex.split(f"curl -s {tag}")
    p = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return p.stdout


def main() -> None:
    """
    Generate the patches files for clang so it
    can be used by the ROOT version defined by
    the ROOT_TAG variable.
    """
    proc = subprocess.run(
        ["git", "diff", "--exit-code"], capture_output=False, cwd=THIS_DIR.parent.parent
    )
    if proc.returncode != 0:
        raise Exception(
            "Repository is dirty, please add your changes before running this script!"
        )

    recipe_path = THIS_DIR.parent / "meta.yaml"
    recipe_text = recipe_path.read_text()

    llvm_version = re.search(r'version = "([\d\.]+)"', recipe_text).group(1)
    llvm_tag = f"llvmorg-{llvm_version}"
    print(f"Using LLVM tag: {llvm_tag}")

    recipe_name = re.search(r"package:\n +name: (.+)", recipe_text).group(1)
    match recipe_name:
        case "llvm-package":
            llvm_repo_dir = "llvm"
        case "clang_packages":
            llvm_repo_dir = "clang"
        case _:
            raise NotImplementedError(f"Recipe name {recipe_name} not known")

    conda_build_config_text = (THIS_DIR.parent / "conda_build_config.yaml").read_text()
    match = re.search(r"root_(6)(\d\d)(\d\d)", conda_build_config_text)
    root_tag = f"v{match.group(1)}-{match.group(2)}-{match.group(3)}"
    print(f"Using ROOT tag: {root_tag}")

    patch_files_dir = THIS_DIR / "root"
    old_patches_dir = THIS_DIR / "root-old"

    root_llvm_tag = retrieve_root_llvm_fork_tag(root_tag)
    print(f"Using ROOT LLVM fork tag: {root_llvm_tag}")

    # Look for existing patch files and create a mapping between the name and the number
    # so we can minimise the diff we are going to generate to the feedstock
    patch_mapping = {}
    for exisiting_patch in patch_files_dir.glob("*.patch"):
        n, name = exisiting_patch.name.split("-", 1)
        patch_mapping[name] = int(n)

    # Remove the old patches directory and move the current patches to it so we
    # can compare them with the new ones
    if patch_files_dir.exists():
        if old_patches_dir.exists():
            shutil.rmtree(old_patches_dir)
        shutil.move(patch_files_dir, old_patches_dir)
    os.makedirs(patch_files_dir)

    patch_files = []
    try:
        # Clone the fork and fetch the correct upstream tag
        subprocess.run(
            shlex.split(
                f"git clone --depth 1000 --single-branch --branch {root_llvm_tag} https://github.com/root-project/llvm-project.git"
            ),
            check=True,
        )

        # Generate the patch files between the two tags
        with change_directory("llvm-project"):
            subprocess.run(
                shlex.split(
                    "git remote add upstream https://github.com/llvm/llvm-project.git"
                ),
                check=True,
            )
            subprocess.run(
                shlex.split(
                    f"git fetch --no-tags upstream refs/tags/{llvm_tag}:refs/tags/{llvm_tag}"
                ),
                check=True,
            )
            # Only create patch files for the commits related to llvm
            subprocess.run(
                shlex.split(
                    f"git format-patch --no-signature refs/tags/{llvm_tag} -- {llvm_repo_dir}/"
                ),
                check=True,
            )

            # Move files to the patch directory
            for original_name in sorted(glob.glob("*.patch")):
                print("Processing patch:", original_name)
                patch_files.append(original_name)
                src = original_name
                if patch_mapping:
                    key = original_name.split("-", 1)[1]
                    if key in patch_mapping:
                        pattern = re.compile(r"(index )[0-9a-f]+\.\.[0-9a-f]+( \d+)")
                        n = patch_mapping[key]

                        reference_patch = (old_patches_dir / f"{n:04d}-{key}").read_text()
                        a = pattern.sub(r"\1xxx\2", reference_patch.split("---", 1)[1])

                        new_patch = Path(original_name).read_text()
                        b = pattern.sub(r"\1xxx\2", new_patch.split("---", 1)[1])

                        if a == b:
                            src = old_patches_dir / f"{n:04d}-{key}"
                            print("Found identical patch, changing source to:", src)
                shutil.copy2(src, patch_files_dir / original_name)
    finally:
        shutil.rmtree("llvm-project")

    # Update the conda_build_config.yaml file with the new patches
    split_1 = '{% if variant and variant.startswith("root_") %}'
    split_2 = "{% endif %}"
    # If there is more than one split then we want this to crash
    prefix, suffix = recipe_text.split(split_1)
    _, suffix = suffix.split(split_2, maxsplit=1)
    # Detect the indentation level of the patches
    whitespace, _ = prefix.split("\n")[-2].split("-", 1)
    # Make the new recipe text
    new_recipe_text = [prefix + split_1]
    for patch in patch_files:
        new_recipe_text.append(f"{whitespace}- patches/root/{patch}")
    new_recipe_text += [split_2 + suffix]

    recipe_path.write_text("\n".join(new_recipe_text))


if __name__ == "__main__":
    with change_directory(os.path.dirname(__file__)):
        raise SystemExit(main())
