# CreateAssemblyInfoFromGit

CreateAssemblyInfoFromGit is a MSBuild task creating a `CommonAssemblyInfo.cs` based on the git repository. 

## How the version is determined

### vX.Y[.Z]

CreateAssemblyInfoFromGit walks the commits backwards until it finds a tag with the format vX.Y[.Z]. It takes this version and appends the distance to _HEAD_ as the build number, e.g. the number of commits since the tag. With this information it generates a file named `CommonAssemblyInfo.cs` in the solution folder. E.g. if you have a tag named _v1.0.0_, six commits later the MSBUild task would write following content to `CommonAssemblyInfo.cs`:

    // Generated: 05/31/2013 16:51:56 (UTC)
    // Warning: This is generated code! Don't touch as it will be overridden by the build process.
    
    using System.Reflection;
    
    [assembly: AssemblyVersion("1.0.0.6")]
    [assembly: AssemblyFileVersion("1.0.0.6")]
    [assembly: AssemblyInformationalVersion("1.0.0.6")]
    
### vNext-X.Y[.Z]

However, it gets more interesting when you plan a new release for your software. If for example the next release would be 2.0, you create a tag named `vNext-2.0`. From now on CreateAssemblyInfoFromGit creates a [Semantic Version](http://semver.org). In this example, three commits after the vNext-2.0 tag, the task would create this `CommonAssemblyInfo.cs`:

    // Generated: 05/31/2013 16:55:17 (UTC)
    // Warning: This is generated code! Don't touch as it will be overridden by the build process.
    
    using System.Reflection;
    
    [assembly: AssemblyVersion("2.0.0.6")]
    [assembly: AssemblyFileVersion("2.0.0.6")]
    [assembly: AssemblyInformationalVersion("2.0.0-beta6")]
    
## Usage

Just add the NuGet package [CreateAssemblyInfoFromGit](https://nuget.org/packages/CreateAssemblyInfoFromGit/) to your project. The package adds the CreateAssemblyInfoFromGit MSBuild task and a link to `CommonAssemblyInfo.cs` in the solution folder.

From now on whenever your project is built and there are new commits, `CommonAssemblyInfo.cs` will be updated.