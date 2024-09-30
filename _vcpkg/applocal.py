import argparse
import glob
from pathlib import Path
from shutil import copyfile
import sys

import lief


def applocal_copy(args: argparse.Namespace) -> None:
    binary_repr = lief.parse(str(args.target_binary))

    if not binary_repr:
        print(f"Failed to parse binary: '{args.target_binary}'", file=sys.stderr)
        sys.exit(1)

    for dependency in binary_repr.abstract.libraries:
        dependency = Path(dependency).name

        if (dst := args.target_binary.parent / dependency).is_file():
            continue

        for src in glob.iglob(
            str(args.installed_dir / "**" / dependency), recursive=True
        ):
            src_repr = lief.parse(src)

            if not src_repr or src_repr.format != binary_repr.format:
                continue

            copyfile(src, dst)
            applocal_copy(
                argparse.Namespace(target_binary=dst, installed_dir=args.installed_dir)
            )

            break


if __name__ == "__main__":
    lief.logging.disable()

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--target-binary",
        dest="target_binary",
        required=True,
        type=lambda s: Path(s).resolve(strict=True),
    )
    parser.add_argument(
        "--installed-dir",
        dest="installed_dir",
        required=True,
        type=lambda s: Path(s).resolve(strict=True),
    )

    parsed_args = parser.parse_args()
    applocal_copy(parsed_args)
