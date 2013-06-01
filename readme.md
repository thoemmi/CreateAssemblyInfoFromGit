# CreateAssemblyInfoFromGit

CreateAssemblyInfoFromGit is a MSBuild task creating a `CommonAssemblyInfo.cs` based on the git repository.

The goal is to create a predictable version schema for your project. The generated versions follows [Semantic Versioning](http://semver.org)

## How the version is determined

### vX.Y

CreateAssemblyInfoFromGit walks the commits backwards until it finds a tag with the format `vX.Y`. It takes this version and appends the distance to _HEAD_ as the build number, e.g. the number of commits since the tag. With this information it generates a file named `CommonAssemblyInfo.cs` in the solution folder. E.g. if you have a tag named _v1.0_, six commits later the MSBUild task would write following content to `CommonAssemblyInfo.cs`:

    // Generated: 05/31/2013 16:51:56 (UTC)
    // Warning: This is generated code! Don't touch as it will be overridden by the build process.
    
    using System.Reflection;
    
    [assembly: AssemblyVersion("1.0.6.0")]
    [assembly: AssemblyFileVersion("1.0.6.0")]
    [assembly: AssemblyInformationalVersion("1.0.6")]
    
The major and minor components of the version are determined by the tag, the build component is the number of commits since the tag. 

If the _HEAD_ is tagged with `vX.Y`, the release component is the number of commits since the previous `vNext-X.Y` tag; otherwise, it is `0`. This is to guarantee that versions are always increasing. See the line with the v-1.0 tag in the table below: The file version of the v1.0 release is greater than the beta version before. 

### vNext-X.Y

However, it gets more interesting when you plan a new release for your software. If for example the next release would be 2.0, you create a tag named like `vNext-2.0`. Three commits later, the task would create this `CommonAssemblyInfo.cs`:

    // Generated: 05/31/2013 16:55:17 (UTC)
    // Warning: This is generated code! Don't touch as it will be overridden by the build process.
    
    using System.Reflection;
    
    [assembly: AssemblyVersion("2.0.0.3")]
    [assembly: AssemblyFileVersion("2.0.0.3")]
    [assembly: AssemblyInformationalVersion("2.0.0-beta.3")]

Here the major and minor components of the version are determined by the tag, the build component is 0, and the release component is the number of commits since the tag.
    
## Example

Here's a table how I test the version generation. Each row represents a commit with optional tags attached:

    Tags              File     Display       Description
    -----------------------------------------------------------------------------
                      0.0.0.0  0.0.0-beta.0  
                      0.0.0.1  0.0.0-beta.1  
    vNext-1.0         1.0.0.0  1.0.0-beta.0  Started working on v1.0
                      1.0.0.1  1.0.0-beta.1
                      1.0.0.2  1.0.0-beta.2
    v-1.0             1.0.0.3  1.0.0         Release v1.0
                      1.0.1.0  1.0.1
		              1.0.2.0  1.0.2
    vNext-1.1         1.1.0.0  1.1.0-beta.0  Next release will be 1.1
                      1.1.0.1  1.1.0-beta.1
    v-1.1, vNext-1.2  1.1.0.2  1.1.0         Release v1.1, started working on v1.2
                      1.2.0.1  1.2.0-beta.1			

## Usage

Just add the NuGet package [CreateAssemblyInfoFromGit](https://nuget.org/packages/CreateAssemblyInfoFromGit/) to your project. The package adds the CreateAssemblyInfoFromGit MSBuild task and a link to `CommonAssemblyInfo.cs` in the solution folder.

From now on whenever your project is built and there are new commits, `CommonAssemblyInfo.cs` will be updated.