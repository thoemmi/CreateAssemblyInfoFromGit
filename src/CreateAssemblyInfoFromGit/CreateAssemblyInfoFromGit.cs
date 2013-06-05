using System;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace CreateAssemblyInfoFromGit {
    public class CreateAssemblyInfoFromGit : Task {
        [Required]
        public ITaskItem Repository { get; set; }

        [Required]
        public ITaskItem AssemblyInfoPath { get; set; }

        public override bool Execute() {
            var version = GitHelper.GetVersion(Repository.ItemSpec);
            return CreateOrUpdateAssemblyInfo(AssemblyInfoPath.ItemSpec, version, str => Log.LogMessage(str));
        }

        public static bool CreateOrUpdateAssemblyInfo(string path, CommonVersion version, Action<string> log = null) {
            if (File.Exists(path)) {
                var oldContent = File.ReadAllText(path);
                if (oldContent.Contains(@"AssemblyInformationalVersion(""" + version.AssemblyInformationalVersion + @""")")) {
                    if (log != null) {
                        log(path + " is up-to-date.");
                    }
                    return true;
                }
            }

            var content = String.Format(@"// Generated: {0} (UTC)
// Warning: This is generated code! Don't touch as it will be overridden by the build process.

using System.Reflection;

[assembly: AssemblyVersion(""{1}"")]
[assembly: AssemblyFileVersion(""{1}"")]
[assembly: AssemblyInformationalVersion(""{2}"")]", DateTime.UtcNow, version.AssemblyVersion, version.AssemblyInformationalVersion);
            File.WriteAllText(path, content);
            if (log != null) {
                log("New AssemblyInfo written to " + path + ".");
            }
            return true;
        }
    }
}