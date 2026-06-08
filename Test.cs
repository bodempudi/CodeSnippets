private static Assembly LoadDependency(
    object sender,
    ResolveEventArgs args)
{
    try
    {
        string assemblyFile =
            Path.Combine(
                Npp.pluginDllDirectory,
                new AssemblyName(args.Name).Name) +
            ".dll";

        if (!File.Exists(assemblyFile))
        {
            MessageBox.Show(
                "Missing dependency:\n" + assemblyFile,
                "SQLStandardFormatter");

            return null;
        }

        Assembly assembly =
            Assembly.LoadFrom(
                assemblyFile);

        MessageBox.Show(
            "Loaded OK:\n" + assembly.FullName,
            "SQLStandardFormatter");

        return assembly;
    }
    catch (Exception ex)
    {
        MessageBox.Show(
            ex.ToString(),
            "Assembly Load Error");

        return null;
    }
}
