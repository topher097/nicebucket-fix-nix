import { describe, expect, it } from "vitest";

import { getFlatDownloadName, getFolderZipBaseName } from "./utils";

describe("getFlatDownloadName", () => {
  it("returns the last path segment for nested keys", () => {
    expect(getFlatDownloadName("folder/subfolder/file.txt")).toBe("file.txt");
  });

  it("returns the key when there are no slashes", () => {
    expect(getFlatDownloadName("file.txt")).toBe("file.txt");
  });

  it("handles trailing slashes by ignoring empty segments", () => {
    expect(getFlatDownloadName("folder/subfolder/")).toBe("subfolder");
  });
});

describe("getFolderZipBaseName", () => {
  it("flattens nested prefixes with underscores", () => {
    expect(getFolderZipBaseName("folder/subfolder/")).toBe("folder_subfolder");
  });

  it("handles prefixes without trailing slash", () => {
    expect(getFolderZipBaseName("folder/subfolder")).toBe("folder_subfolder");
  });

  it("falls back to default name for empty prefix", () => {
    expect(getFolderZipBaseName("")).toBe("download");
  });
});
