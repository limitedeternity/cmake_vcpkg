import argparse
from collections import OrderedDict
import json
from numbers import Number
from pathlib import Path
import re
from typing import Any, List, TypedDict, get_origin, get_args

Dependency = TypedDict(
    "Dependency", {"name": str, "default-features": bool, "features": List[str]}
)

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
    root = Path(__file__).resolve().parent.parent
    vcpkg_json_path = root / "vcpkg.json"

    vcpkg_json: VCPkgJson = {
        "name": root.name,
        "version-semver": "1.0.0",
        "dependencies": [],
        "overrides": [],
        "builtin-baseline": "74808c9892fcece2012b65c2ebcc1fa128db9c93",
    }

    if vcpkg_json_path.exists():
        with vcpkg_json_path.open(mode="r", encoding="utf-8") as f:
            vcpkg_json = json.load(f, object_pairs_hook=OrderedDict)

        if not validate_config(VCPkgJson, vcpkg_json):
            raise AssertionError(
                f"Validation failed: {vcpkg_json_path.name} didn't match type annotations"
            )

    match = re.match(r"^([a-z0-9-]+)(?:\[(.+)])?$", args.name)

    if not match:
        raise AssertionError(
            f"Validation failed: {args.name!r} is not a valid package name"
        )

    package_name, package_features = match.groups(default="")
    package_feature_list: List[str] = list(
        filter(None, map(str.strip, package_features.split(",")))
    )

    dependency_obj: Dependency = {
        "name": package_name,
        "default-features": not bool(package_feature_list),
        "features": package_feature_list,
    }

    for index, dependency in enumerate(
        vcpkg_json["dependencies"]
    ):  # type: int, Dependency
        if dependency["name"] == dependency_obj["name"]:
            vcpkg_json["dependencies"][index] = dependency_obj
            break

    else:
        vcpkg_json["dependencies"].append(dependency_obj)

    override_obj: Override = {"name": package_name, "version": args.version}

    if args.version:
        for index, override in enumerate(
            vcpkg_json["overrides"]
        ):  # type: int, Override
            if override["name"] == override_obj["name"]:
                vcpkg_json["overrides"][index] = override_obj
                break

        else:
            vcpkg_json["overrides"].append(override_obj)

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
