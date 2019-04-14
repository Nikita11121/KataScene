using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ValuesGUI : MonoBehaviour {

    public RectTransform item;
    private List<RectTransform> _items = new List<RectTransform>();
    public RectTransform rectContent;

    private Dictionary<Values.StatusValue, string> _statusString = new Dictionary<Values.StatusValue, string>();

    private void RefreshValues()
    {
        item.gameObject.SetActive(false);
        int i = -1;
        foreach(var valueRecord in Values.GetValues())
        {
            i++;
            var value = valueRecord.Value;
            RectTransform currItem;
            if (i >= _items.Count)
            {
                GameObject itemGO = Instantiate(item.gameObject);
                itemGO.SetActive(true);
                currItem = itemGO.GetComponent<RectTransform>();
                currItem.SetParent(item.parent);
                currItem.localScale = Vector3.one;
                currItem.localRotation = Quaternion.identity;
                currItem.anchoredPosition = new Vector2(item.anchoredPosition.x, i * item.sizeDelta.y);
                currItem.sizeDelta = item.sizeDelta;
                _items.Add(currItem);

                int _i = i;
                foreach (var str in _statusString)
                {
                    Transform valueTrans = currItem.Find(str.Value);
                    bool isVisible = str.Key == valueRecord.Value.status;
                    valueTrans.gameObject.SetActive(isVisible);

                    InputField input = valueTrans.GetComponent<InputField>();
                    if (input != null)
                    {
                        //input.onValueChange.RemoveAllListeners();
                        input.onValueChange.AddListener((val) => OnChangeValue(input, currItem.GetChild(0).GetComponent<Text>(), str.Key, val));
                    }
                    else
                    {
                        for (int j = 0; j < valueTrans.childCount; j++)
                        {
                            int _j = j;
                            //valueTrans.GetChild(j).GetComponent<InputField>().onValueChange.RemoveAllListeners();
                            InputField input2 = valueTrans.GetChild(j).GetComponent<InputField>();
                            input2.onValueChange.AddListener((val) => OnChangeValue(input2, currItem.GetChild(0).GetComponent<Text>(), str.Key, val, _j));
                        }
                    }
                }
            }
            else
                currItem = _items[i];

            currItem.GetChild(0).GetComponent<Text>().text = value.name;
            foreach(var str in _statusString)
            {
                currItem.Find(str.Value).gameObject.SetActive(value.status == str.Key);
            }

            Transform stringTrans = currItem.Find(_statusString[value.status]);
            InputField mainInput = stringTrans.GetComponent<InputField>();
            bool isCanChange = mainInput == null || !mainInput.isFocused;
            if (mainInput == null)
            {
                for (int j = 0; j < stringTrans.childCount; j++)
                    isCanChange &= !stringTrans.GetChild(j).GetComponent<InputField>().isFocused;
            }

            if (!isCanChange)
                continue;
            switch (value.status)
            {
                case Values.StatusValue.NONE:
                    stringTrans.GetComponent<Text>().text = value.value.ToString();
                    break;
                case Values.StatusValue.STRING:
                case Values.StatusValue.INT:
                case Values.StatusValue.DOUBLE:
                    mainInput.text = value.value.ToString();
                    break;
                case Values.StatusValue.VECTOR2:
                    stringTrans.GetChild(0).GetComponent<InputField>().text = ((Vector2)value.value).x.ToString();
                    stringTrans.GetChild(1).GetComponent<InputField>().text = ((Vector2)value.value).y.ToString();
                    break;
                case Values.StatusValue.VECTOR3:
                    stringTrans.GetChild(0).GetComponent<InputField>().text = ((Vector3)value.value).x.ToString();
                    stringTrans.GetChild(1).GetComponent<InputField>().text = ((Vector3)value.value).y.ToString();
                    stringTrans.GetChild(2).GetComponent<InputField>().text = ((Vector3)value.value).z.ToString();
                    break;
                case Values.StatusValue.VECTOR4:
                    if (value.value is Vector4)
                    {
                        stringTrans.GetChild(0).GetComponent<InputField>().text = ((Vector4)value.value).x.ToString();
                        stringTrans.GetChild(1).GetComponent<InputField>().text = ((Vector4)value.value).y.ToString();
                        stringTrans.GetChild(2).GetComponent<InputField>().text = ((Vector4)value.value).z.ToString();
                        stringTrans.GetChild(3).GetComponent<InputField>().text = ((Vector4)value.value).w.ToString();
                    }
                    else if (value.value is Quaternion)
                    {
                        stringTrans.GetChild(0).GetComponent<InputField>().text = ((Quaternion)value.value).x.ToString();
                        stringTrans.GetChild(1).GetComponent<InputField>().text = ((Quaternion)value.value).y.ToString();
                        stringTrans.GetChild(2).GetComponent<InputField>().text = ((Quaternion)value.value).z.ToString();
                        stringTrans.GetChild(3).GetComponent<InputField>().text = ((Quaternion)value.value).w.ToString();
                    }
                    break;
            }
            //currItem.GetChild(1).GetComponent<Text>().text = values[i].value.ToString();
        }
        rectContent.sizeDelta = new Vector2(rectContent.sizeDelta.x, item.sizeDelta.y * (i + 1));
    }

    private Values.ValueRecord _lastValueRecord;
    private InputField _lastField;
    private Values.StatusValue _lastStatus;
    private int _lastSubIndex;

    private void OnChangeValue(InputField field, Text nameTxt, Values.StatusValue status, string str, int subIndex = -1)
    {
        _lastValueRecord = Values.GetValues()[nameTxt.text];
        _lastField = field;
        _lastStatus = status;
        _lastSubIndex = subIndex;
    }

    private void Start()
    {
        _statusString.Add(Values.StatusValue.NONE, "ValueTxt");
        _statusString.Add(Values.StatusValue.STRING, "InputStr");
        _statusString.Add(Values.StatusValue.INT, "InputInt");
        _statusString.Add(Values.StatusValue.DOUBLE, "InputDouble");
        _statusString.Add(Values.StatusValue.VECTOR2, "Vector2");
        _statusString.Add(Values.StatusValue.VECTOR3, "Vector3");
        _statusString.Add(Values.StatusValue.VECTOR4, "Vector4");
    }

    // Update is called once per frame
    void Update () {
        if(_lastField != null && !_lastField.isFocused)
        {
            string str = _lastField.text;
            switch (_lastStatus)
            {
                case Values.StatusValue.VECTOR2:
                    Vector2 vec2 = (Vector2)_lastValueRecord.value;
                    vec2[_lastSubIndex] = float.Parse(str);
                    _lastValueRecord.value = vec2;
                    break;
                case Values.StatusValue.VECTOR3:
                    Vector3 vec3 = (Vector3)_lastValueRecord.value;
                    vec3[_lastSubIndex] = float.Parse(str);
                    _lastValueRecord.value = vec3;
                    break;
                case Values.StatusValue.VECTOR4:
                    if (_lastValueRecord.value is Vector4)
                    {
                        Vector4 vec4 = (Vector4)_lastValueRecord.value;
                        vec4[_lastSubIndex] = float.Parse(str);
                        _lastValueRecord.value = vec4;
                    }
                    else
                    {
                        Quaternion quat = (Quaternion)_lastValueRecord.value;
                        quat[_lastSubIndex] = float.Parse(str);
                        _lastValueRecord.value = quat;
                    }
                    break;
                default:
                    _lastValueRecord.value = str;
                    break;
            }
            _lastField = null;
        }
        RefreshValues();
    }
}
