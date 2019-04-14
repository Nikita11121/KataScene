using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Values
{

    public enum StatusValue { NONE, INT, DOUBLE, STRING, VECTOR2, VECTOR3, VECTOR4 }
    public class ValueRecord
    {
        public string name;
        public StatusValue status = StatusValue.NONE;
        public UnityAction<ValueRecord> refreshValueAction;
        public UnityAction<object> setValueAction;
        public UnityAction<int> setValueActionInt;
        public UnityAction<double> setValueActionDouble;
        public UnityAction<string> setValueActionString;
        public UnityAction<Vector2> setValueActionVector2;
        public UnityAction<Vector3> setValueActionVector3;
        public UnityAction<Vector4> setValueActionVector4;
        public UnityAction<Quaternion> setValueActionQuaternion;
        private object _value;
        public object value
        {
            get
            {
                try
                {
                    refreshValueAction(this);
                }
                catch { }
                return _value;
            }
            set
            {
                try
                {
                    if (setValueAction != null)
                        setValueAction(value);
                    else if (setValueActionInt != null)
                    {
                        int intValue = -1;
                        if (int.TryParse(value.ToString(), out intValue))
                        {
                            setValueActionInt(intValue);
                        }
                    }
                    else if (setValueActionDouble != null)
                    {
                        double doubleValue = -1;
                        if (double.TryParse(value.ToString(), out doubleValue))
                        {
                            setValueActionDouble(doubleValue);
                        }
                    }
                    else if (setValueActionString != null)
                        setValueActionString(value.ToString());
                    else if (setValueActionVector2 != null)
                        setValueActionVector2((Vector2)value);
                    else if (setValueActionVector3 != null)
                        setValueActionVector3((Vector3)value);
                    else if (setValueActionVector4 != null)
                        setValueActionVector4((Vector4)value);
                    else if (setValueActionQuaternion != null)
                        setValueActionQuaternion((Quaternion)value);
                    _value = value;
                }
                catch { }
                
            }
        }
        public ValueRecord()
        {

        }
        public ValueRecord(string name, StatusValue status = StatusValue.NONE)
        {
            this.name = name;
            this.status = status;
        }
    }

    private static Dictionary<string, ValueRecord> _values = new Dictionary<string, ValueRecord>();

    public static Dictionary<string, ValueRecord> GetValues()
    {
        return _values;
    }

    public static void AddValue(string name, StatusValue status, UnityAction<ValueRecord> refreshValue)
    {
        ValueRecord valueRecord = new ValueRecord(name, status);
        valueRecord.refreshValueAction = refreshValue;
        if (_values.ContainsKey(name))
            _values.Remove(name);
        _values.Add(name, valueRecord);
    }

    public static void AddValue<T>(string name, StatusValue status, UnityAction<ValueRecord> refreshValue, UnityAction<T> setValue = null)
    {
        ValueRecord valueRecord = new ValueRecord(name, status);
        valueRecord.refreshValueAction = refreshValue;
        if (setValue != null)
        {
            if (setValue is UnityAction<int>)
                valueRecord.setValueActionInt = ((int value) => setValue((T)(object)value));
            else if (setValue is UnityAction<double>)
                valueRecord.setValueActionDouble = ((double value) => setValue((T)(object)value));
            else if (setValue is UnityAction<string>)
                valueRecord.setValueActionString = ((string value) => setValue((T)(object)value));
            else if (setValue is UnityAction<Vector2>)
                valueRecord.setValueActionVector2 = ((Vector2 value) => setValue((T)(object)value));
            else if (setValue is UnityAction<Vector3>)
                valueRecord.setValueActionVector3 = ((Vector3 value) => setValue((T)(object)value));
            else if (setValue is UnityAction<Vector4>)
                valueRecord.setValueActionVector4 = ((Vector4 value) => setValue((T)(object)value));
            else if (setValue is UnityAction<Quaternion>)
                valueRecord.setValueActionQuaternion = ((Quaternion value) => setValue((T)(object)value));
            else
                valueRecord.setValueAction = ((object obj) => setValue((T)obj));
        }
        if (_values.ContainsKey(name))
            _values.Remove(name);
        _values.Add(name, valueRecord);
    }
}
