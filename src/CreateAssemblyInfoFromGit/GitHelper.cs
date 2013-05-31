using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using LibGit2Sharp;

namespace CreateAssemblyInfoFromGit {
    public class CommonVersion {
        public string AssemblyVersion { get; set; }
        public string AssemblyInformationalVersion { get; set; }
    }

    public static class GitHelper {
        public static CommonVersion GetVersion(string path) {
            using (var repository = new Repository(GetGitRepositoryPath(path))) {
                var allTags = repository.Tags.ToList();

                var build = -1;
                var isPreliminary = false;
                string version = null;
                var justCountingTillVNext = false;
                foreach (var commit in repository.Head.Commits) {
                    build++;
                    var tags = allTags.Where(t => t.IsAnnotated && t.Target == commit).ToList();
                    if (build == 0 && TryGetVersion(tags, @"v\-?", out version)) {
                        justCountingTillVNext = true;
                        continue;
                    }
                    if (justCountingTillVNext) {
                        string dummy;
                        if (TryGetVersion(tags, @"vNext\-?", out dummy)) {
                            break;
                        }
                    } else {
                        if (TryGetVersion(tags, @"vNext\-?", out version)) {
                            isPreliminary = true;
                            break;
                        }
                        if (TryGetVersion(tags, @"v\-?", out version)) {
                            break;
                        }
                    }
                }

                if (version == null) {
                    return new CommonVersion {
                        AssemblyVersion = "0.0.0." + build,
                        AssemblyInformationalVersion = "0.0.0-beta" + build
                    };
                } else if (isPreliminary) {
                    return new CommonVersion {
                        AssemblyVersion = version + ".0." + build,
                        AssemblyInformationalVersion = version + ".0-beta" + build
                    };
                } else if (justCountingTillVNext) {
                    return new CommonVersion {
                        AssemblyVersion = version + ".0." + build,
                        AssemblyInformationalVersion = version + ".0"
                    };
                } else {
                    return new CommonVersion {
                        AssemblyVersion = version + "." + build + ".0",
                        AssemblyInformationalVersion = version + "." + build
                    };
                }
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
            string pattern = @"^" + prefix + @"(?<minormajor>\d+\.\d+)?$";
            foreach (var tag in tags) {
                var match = Regex.Match(tag.Name, pattern);
                if (match.Success) {
                    version = match.Groups["minormajor"].Value;
                    return true;
                }
            }
            version = default(string);
            return false;
        }
    }
}