// Native executable stub: batch files must observe a real process exit code.
using System;
using System.IO;
class MkvmergeStub {
    static int Main(string[] args) {
        File.WriteAllLines(Environment.GetEnvironmentVariable("STUB_ARGS"), args);
        Console.WriteLine("stub diagnostic");
        int code = Int32.Parse(Environment.GetEnvironmentVariable("STUB_EXIT"));
        if ((code == 0 || code == 1) &&
            Environment.GetEnvironmentVariable("STUB_NO_OUTPUT") != "1") {
            int output = Array.IndexOf(args, "-o") + 1;
            File.WriteAllText(args[output],
                Environment.GetEnvironmentVariable("STUB_EMPTY") == "1" ? "" : "synthetic output");
        }
        return code;
    }
}
