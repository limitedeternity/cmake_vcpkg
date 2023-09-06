import argparse
from collections import OrderedDict
import json
from numbers import Number
from pathlib import Path
from typing import Any, List, TypedDict, get_origin, get_args

Dependency = TypedDict("Dependency", {"name": str})
Override = TypedDict("Override", {"name": str, "version": str})
VCPkgJson = TypedDict(
    "VCPkgJson",
    {
        "name": str,
        "version-semver": str,
        "dependencies": List[Dependency],
        "overrides": List[Override],
        "builtin-baseline": str,
    },
)


def validate_config(model: Any, instance: Any) -> bool:
    if isinstance(instance, (str, Number)):
        return isinstance(instance, model)

    ctor = get_origin(model)
    params = get_args(model)

    if ctor in (list, set):
        return isinstance(instance, ctor) and all(
            validate_config(params[0], value) for value in instance
        )

    if ctor is dict:
        return isinstance(instance, ctor) and all(
            validate_config(params[0], key) and validate_config(params[1], value)
            for key, value in instance.items()
        )

    for prop_name, prop_type in model.__annotations__.items():
        sentinel = object()
        extracted_value = instance.get(prop_name, sentinel)

        if extracted_value is sentinel or not validate_config(
            prop_type, extracted_value
        ):
            return False

    return True


def add_package(args: argparse.Namespace) -> None:
    root = Path(__file__).parent.parent
    vcpkg_json_path = root / "vcpkg.json"

    vcpkg_json: VCPkgJson = {
        "name": root.name,
        "version-semver": "0.1.0",
        "dependencies": [],
        "overrides": [],
        "builtin-baseline": "9edb1b8e590cc086563301d735cae4b6e732d2d2",
    }

    if vcpkg_json_path.exists():
        with vcpkg_json_path.open(mode="r", encoding="utf-8") as f:
            vcpkg_json = json.load(f, object_pairs_hook=OrderedDict)

        if not validate_config(VCPkgJson, vcpkg_json):
            raise AssertionError(
                f"Validation failed: {vcpkg_json_path.name} didn't match type annotations"
            )

    for depend in vcpkg_json["dependencies"]:
        if depend["name"] == args.name:
            break
    else:
        vcpkg_json["dependencies"].append({"name": args.name})

    if args.version:
        for index, depend in enumerate(vcpkg_json["overrides"]):
            if depend["name"] == args.name:
                vcpkg_json["overrides"][index]["version"] = args.version
                break
        else:
            vcpkg_json["overrides"].append({"name": args.name, "version": args.version})

    with vcpkg_json_path.open(mode="w", encoding="utf-8") as f:
        json.dump(vcpkg_json, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("name", type=str.lower)
    parser.add_argument("--version", nargs="?")

    parsed_args = parser.parse_args()
    print(
        f"-- vcpkg: Adding package {parsed_args.name}@{parsed_args.version or 'latest'}"
    )

    add_package(parsed_args)
