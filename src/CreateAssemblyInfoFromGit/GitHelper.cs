using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using LibGit2Sharp;

namespace CreateAssemblyInfoFromGit {
    public static class GitHelper {
        public static string GetVersion(string path) {
            using (var repository = new Repository(GetGitRepositoryPath(path))) {
                var allTags = repository.Tags.ToList();

                var build = 0;
                var isPreliminary = false;
                string version = null;
                foreach (var commit in repository.Head.Commits) {
                    var tags = allTags.Where(t => t.IsAnnotated && t.Target == commit).ToList();
                    if (build == 0 && TryGetVersion(tags, @"v\-?", out version)) {
                        break;
                    }
                    if (TryGetVersion(tags, @"vNext\-?", out version)) {
                        isPreliminary = true;
                        break;
                    }
                    if (TryGetVersion(tags, @"v\-?", out version)) {
                        break;
                    }

                    build++;
                }

                if (version == null) {
                    version = "0.0.0-beta" + build;
                } else if (isPreliminary) {
                    version += "-beta" + build;
                } else {
                    version += "." + build;
                }
                return version;
            }
        }

        public static string GetGitRepositoryPath(string path) {
            if (path == null) throw new ArgumentNullException("path");

            //If we are passed a .git directory, just return it straightaway
            var pathDirectoryInfo = new DirectoryInfo(path);
            if (pathDirectoryInfo.Name == ".git") {
                return path;
            }

            if (!pathDirectoryInfo.Exists) {
                return Path.Combine(path, ".git");
            }

            DirectoryInfo checkIn = pathDirectoryInfo;

            while (checkIn != null) {
                var pathToTest = Path.Combine(checkIn.FullName, ".git");
                if (Directory.Exists(pathToTest)) {
                    return pathToTest;
                } else {
                    checkIn = checkIn.Parent;
                }
            }

            // This is not good, it relies on the rest of the code being ok
            // with getting a non-git repo dir
            return Path.Combine(path, ".git");
        }

        private static bool TryGetVersion(IEnumerable<Tag> tags, string prefix, out string version) {
            string pattern = @"^" + prefix + @"(?<minormajor>\d+\.\d+)(?<patch>\.\d+)?$";
            foreach (var tag in tags) {
                var match = Regex.Match(tag.Name, pattern);
                if (match.Success) {
                    var minormajor = match.Groups["minormajor"].Value;
                    var patch = match.Groups["patch"].Value;
                    version = minormajor + (String.IsNullOrEmpty(patch) ? String.Empty : patch);
                    return true;
                }
            }
            version = default(string);
            return false;
        }
    }
}