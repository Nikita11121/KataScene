using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Console {

    public class RecordLog
    {
        public DateTime time;
        public string message;
        public RecordLog(string message)
        {
            time = DateTime.Now;
            this.message = message;
        }
    }

    private static Dictionary<string, List<RecordLog>> _logs =
        new Dictionary<string, List<RecordLog>>();

    public static void Send(string str)
    {
        string[] words = str.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
        if (words.Length < 1)
            return;
        for (int i = 0; i < words.Length; i++)
            words[i] = words[i].ToLower();

        if (words[0] == "clear")
        {
            if (words.Length == 1)
                Clear();
            else if (words.Length == 2)
            {
                Clear(words[1]);
            }
        }
    }

    public static List<string> GetNamesCategory()
    {
        List<string> names = new List<string>();
        foreach (var key in _logs.Keys)
        {
            names.Add(key);
        }
        return names;
    }

    public static string GetCategoryLogString(string category)
    {
        if (!_logs.ContainsKey(category))
            return "";
        List<RecordLog> records = _logs[category];
        string outStr = "";
        for(int i = records.Count - 1; i >= 0; i--)
        {
            if(outStr.Length + records[i].message.Length < 16000)
                outStr = "- " + records[i].message + "\n" + outStr;
            else
            {
                for(int j = i; j >= 0; j--)
                    records.RemoveAt(j);
                break;
            }
        }
        return outStr;
    }

    public static void Log(string str)
    {
        Log(str, "INFO");
    }

    public static void Log(string str, string nameCategory, bool isDebugOut = true)
    {
        if (!_logs.ContainsKey(nameCategory))
            _logs.Add(nameCategory, new List<RecordLog>());
        _logs[nameCategory].Add(new RecordLog(str));
        if (_logs[nameCategory].Count > 1000)
            _logs[nameCategory].RemoveAt(0);
        if (isDebugOut)
            Debug.Log(str);
    }

    public static void LogWarning(string str)
    {
        Log(str, "WARNING", false);
        Debug.LogWarning(str);
    }

    public static void LogError(string str)
    {
        Log(str, "ERROR", false);
        Debug.LogError(str);
    }

    public static void Clear(string nameCategory = null)
    {
        if(nameCategory == null)
            _logs.Clear();
        else
        {
            foreach (var key in _logs.Keys)
            {
                if (key.ToLower() == nameCategory.ToLower())
                {
                    _logs.Remove(key);
                    return;
                }
            }
        }
    }
}
