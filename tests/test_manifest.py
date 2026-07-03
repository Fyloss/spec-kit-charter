"""Tests for the Charter extension manifest and structure."""
import pytest
from pathlib import Path
import yaml


EXTENSION_ROOT = Path(__file__).parent.parent


class TestManifest:
    """Validate extension.yml manifest."""

    def setup_method(self):
        with open(EXTENSION_ROOT / "extension.yml") as f:
            self.manifest = yaml.safe_load(f)

    def test_schema_version(self):
        assert self.manifest["schema_version"] == "1.0"

    def test_extension_id(self):
        ext = self.manifest["extension"]
        assert ext["id"] == "charter"
        assert ext["id"].islower()
        assert all(c.isalnum() or c == "-" for c in ext["id"])

    def test_extension_version(self):
        version = self.manifest["extension"]["version"]
        parts = version.split(".")
        assert len(parts) == 3
        assert all(p.isdigit() for p in parts)

    def test_required_fields(self):
        ext = self.manifest["extension"]
        for field in ["id", "name", "version", "description", "author", "repository", "license"]:
            assert field in ext, f"Missing required field: {field}"

    def test_requires_speckit_version(self):
        assert "requires" in self.manifest
        assert "speckit_version" in self.manifest["requires"]
        assert self.manifest["requires"]["speckit_version"].startswith(">=")

    def test_commands_exist(self):
        commands = self.manifest["provides"]["commands"]
        assert len(commands) >= 3

        for cmd in commands:
            assert cmd["name"].startswith("speckit.charter.")
            cmd_file = EXTENSION_ROOT / cmd["file"]
            assert cmd_file.exists(), f"Command file not found: {cmd_file}"

    def test_command_names_valid(self):
        import re
        pattern = re.compile(r"^speckit\.[a-z0-9-]+\.[a-z0-9-]+$")
        for cmd in self.manifest["provides"]["commands"]:
            assert pattern.match(cmd["name"]), f"Invalid command name: {cmd['name']}"

    def test_tags(self):
        assert "tags" in self.manifest
        assert len(self.manifest["tags"]) >= 2


class TestStructure:
    """Validate extension directory structure."""

    def test_required_files(self):
        for name in ["extension.yml", "README.md", "LICENSE", "CHANGELOG.md"]:
            assert (EXTENSION_ROOT / name).exists(), f"Missing required file: {name}"

    def test_commands_dir(self):
        commands_dir = EXTENSION_ROOT / "commands"
        assert commands_dir.is_dir()
        md_files = list(commands_dir.glob("*.md"))
        assert len(md_files) >= 3

    def test_scripts_dir(self):
        scripts_dir = EXTENSION_ROOT / "scripts" / "bash"
        assert scripts_dir.is_dir()
        sh_files = list(scripts_dir.glob("*.sh"))
        assert len(sh_files) >= 5

    def test_docs_dir(self):
        docs_dir = EXTENSION_ROOT / "docs"
        assert docs_dir.is_dir()

    def test_extensionignore(self):
        assert (EXTENSION_ROOT / ".extensionignore").exists()


class TestFixtures:
    """Validate test fixtures."""

    def test_sample_registry_structure(self):
        registry = EXTENSION_ROOT / "tests" / "fixtures" / "sample-registry"
        assert (registry / "manifest.yml").exists()
        assert (registry / "fragments").is_dir()
        assert (registry / "sub-constitutions").is_dir()

    def test_sample_registry_manifest(self):
        with open(EXTENSION_ROOT / "tests" / "fixtures" / "sample-registry" / "manifest.yml") as f:
            manifest = yaml.safe_load(f)
        assert "version" in manifest
        assert "name" in manifest
        assert "mandatory_fragments" in manifest
        assert "recommended_fragments" in manifest

    def test_sample_registry_has_fragments(self):
        fragments = EXTENSION_ROOT / "tests" / "fixtures" / "sample-registry" / "fragments"
        md_files = list(fragments.rglob("*.md"))
        assert len(md_files) >= 3

    def test_sample_registry_has_sub_constitutions(self):
        sub = EXTENSION_ROOT / "tests" / "fixtures" / "sample-registry" / "sub-constitutions"
        md_files = list(sub.glob("*.md"))
        assert len(md_files) >= 1
