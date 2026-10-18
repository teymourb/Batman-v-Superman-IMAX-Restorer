// Native synthetic stage tool. Deliberately writes a partial output on failure.
using System;
using System.IO;
class StageStub {
    static int Main(string[] args) {
        string trace = Environment.GetEnvironmentVariable("STAGE_TRACE");
        int index = File.Exists(trace) ? File.ReadAllLines(trace).Length + 1 : 1;
        File.AppendAllText(trace, String.Join("|", args) + Environment.NewLine);
        string output = null;
        for (int i = 0; i < args.Length - 1; i++)
            if (args[i] == "-o" || args[i] == "--save") output = args[i + 1];
        if (output == null) output = args[args.Length - 1];
        bool fail = index.ToString() == Environment.GetEnvironmentVariable("STAGE_FAIL_AT");
        string action = fail ? Environment.GetEnvironmentVariable("STAGE_ACTION") : "normal";
        if (action != "missing") {
            Directory.CreateDirectory(Path.GetDirectoryName(output));
            File.WriteAllText(output, action == "empty" ? "" : "synthetic stage bytes");
        }
        Console.WriteLine("synthetic tool stage " + index);
        return fail ? Int32.Parse(Environment.GetEnvironmentVariable("STAGE_CODE")) : 0;
    }
}
