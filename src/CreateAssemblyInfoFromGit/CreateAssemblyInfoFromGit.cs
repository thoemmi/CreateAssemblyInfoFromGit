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

            if (File.Exists(AssemblyInfoPath.ItemSpec)) {
                var oldContent = File.ReadAllText(AssemblyInfoPath.ItemSpec);
                if (Regex.IsMatch(oldContent, @"AssemblyInformationalVersion\(" + version + @"\)")) {
                    Log.LogMessage(MessageImportance.Low, Repository.ItemSpec + " is up-to-date.");
                    return true;
                }
            }

            var fileVersion = version.Replace("-beta", ".");
            var content = String.Format(@"// Generated: {0} (UTC)
// Warning: This is generated code! Don't touch as it will be overridden by the build process.

using System.Reflection;

[assembly: AssemblyVersion(""{1}"")]
[assembly: AssemblyFileVersion(""{1}"")]
[assembly: AssemblyInformationalVersion(""{2}"")]", DateTime.UtcNow, fileVersion, version);
            File.WriteAllText(AssemblyInfoPath.ItemSpec, content);

            return true;
        }
    }
}