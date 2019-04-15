using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using AlchemistRuntimeTool;


public class TestTool : MonoBehaviour
{

    // Use this for initialization
    void Start()
    {
        for (int i = 0; i < 10; i++)
        {
            //Values.AddValue("int_" + i, Values.StatusValue.INT, ((value) => value.value = _int), ((object obj) => _int = int.Parse(obj.ToString())));
            Values.AddValue("int_" + i, Values.StatusValue.INT, ((value) => value.value = _int), ((int value) => { Debug.Log("value = " + value); _int = value; }));
            Values.AddValue("double_" + i, Values.StatusValue.DOUBLE, ((value) => value.value = _double), ((double value) => _double = value));
            Values.AddValue("string_" + i, Values.StatusValue.STRING, ((value) => value.value = _string), ((string value) => _string = value));
            Values.AddValue("v2_" + i, Values.StatusValue.VECTOR2, ((value) => value.value = _v2), ((Vector2 value) => _v2 = value));
            Values.AddValue("v3_" + i, Values.StatusValue.VECTOR3, ((value) => value.value = _v3), ((Vector3 value) => _v3 = value));
            Values.AddValue("v4_" + i, Values.StatusValue.VECTOR4, ((value) => value.value = _v4), ((Vector4 value) => _v4 = value));
            Values.AddValue("quat_" + i, Values.StatusValue.VECTOR4, ((value) => value.value = _quat), ((Quaternion value) => _quat = value));
        }
    }

    private float _timer = 0;
    private object _quat = Quaternion.identity;
    private object _v4 = Vector4.zero;
    private object _v3 = Vector3.up;
    private object _v2 = Vector2.up;
    private object _int = 1;
    private object _double = 1f;
    private object _string = "ghfhjghj";

    // Update is called once per frame
    void Update()
    {
        _timer += Time.deltaTime;
        /* if(Time.time < 8)
                Console.Log("log test" + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time + Time.time);
            */
        /*Console.Log("log test2", "123");
        Console.Log("log test3", "234");
        Console.Log("log test4", "456");
        _string = "DSFDFG" + Time.time;
        _double = Time.time;
        _int = (int)Time.time;*/
        if (_timer > 16.8888888f)
        {
            _timer = 0;
            /*if (Values._values.ContainsKey("int_0"))
            {
                Values._values.Remove("int_8");
                Values._values.Remove("double_8");
            }*/
            /*_quat = new Vector4(Time.time, ((Vector4)_v4).y, ((Vector4)_v4).z, ((Vector4)_v4).w);
            _v4 = new Vector4(Time.time, ((Vector4)_v4).y, ((Vector4)_v4).z, ((Vector4)_v4).w);
            _v3 = new Vector3(Time.time, ((Vector3)_v3).y, ((Vector3)_v3).z);
            _v2 = new Vector2(Time.time, ((Vector2)_v2).y);
            _int = (int)Time.time;
            _double = Time.time;
            _string = "time = " + Time.time;*/
        }
    }
}

