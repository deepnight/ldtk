#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const appDir = path.resolve(scriptDir, "..");
const repositoryDir = path.resolve(appDir, "..");
const packagePath = path.join(appDir, "package.json");
const packageLockPath = path.join(appDir, "package-lock.json");
const changelogPath = path.join(repositoryDir, "docs", "SMARTIVE_CHANGELOG.md");
const semverPattern = /^(\d+)\.(\d+)\.(\d+)$/;

function parseVersion(value) {
	const match = semverPattern.exec(value);
	if (!match) {
		throw new Error(`Expected stable SemVer (major.minor.patch), got: ${value}`);
	}
	return match.slice(1).map(Number);
}

function compareVersions(left, right) {
	for (let index = 0; index < 3; index += 1) {
		if (left[index] !== right[index]) {
			return left[index] - right[index];
		}
	}
	return 0;
}

function formatVersion(parts) {
	return parts.join(".");
}

function calculateNextVersion(current, requested) {
	const next = [...current];
	switch (requested) {
		case "patch":
			next[2] += 1;
			break;
		case "minor":
			next[1] += 1;
			next[2] = 0;
			break;
		case "major":
			next[0] += 1;
			next[1] = 0;
			next[2] = 0;
			break;
		default:
			return parseVersion(requested);
	}
	return next;
}

function writeJson(filePath, value) {
	fs.writeFileSync(filePath, `${JSON.stringify(value, null, "\t")}\n`, "utf8");
}

const requested = process.argv[2];
if (!requested) {
	throw new Error("Usage: node scripts/bump-smartive-version.mjs <patch|minor|major|x.y.z>");
}

const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const currentParts = parseVersion(packageJson.version);
const nextParts = calculateNextVersion(currentParts, requested);
const nextVersion = formatVersion(nextParts);

if (nextParts[0] < 1) {
	throw new Error(`LDTK-Smartive versioning starts at 1.0.0; refusing ${nextVersion}`);
}
if (compareVersions(nextParts, currentParts) <= 0) {
	throw new Error(`New version ${nextVersion} must be greater than ${packageJson.version}`);
}

const previousVersion = packageJson.version;
packageJson.version = nextVersion;
writeJson(packagePath, packageJson);

if (fs.existsSync(packageLockPath)) {
	const packageLock = JSON.parse(fs.readFileSync(packageLockPath, "utf8"));
	packageLock.version = nextVersion;
	if (packageLock.packages?.[""]) {
		packageLock.packages[""].version = nextVersion;
	}
	writeJson(packageLockPath, packageLock);
}

const heading = `# ${nextVersion}`;
const currentChangelog = fs.existsSync(changelogPath)
	? fs.readFileSync(changelogPath, "utf8")
	: "";
if (!currentChangelog.split(/\r?\n/).includes(heading)) {
	const section = `${heading}\n\n- TODO: replace this line with the release changes before publishing.\n\n`;
	fs.writeFileSync(changelogPath, section + currentChangelog, "utf8");
}

console.log(`LDTK-Smartive version: ${previousVersion} -> ${nextVersion}`);
console.log("Update docs/SMARTIVE_CHANGELOG.md, commit the changed files, and push the branch.");
