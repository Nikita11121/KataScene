using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleGUI : MonoBehaviour {

    public Dropdown categoryDrop;
    private List<string> _categorysNames;
    public Text logText;
    private int _categotyIndex = 0;
    public RectTransform rectContent;
    public InputField sendInput;
    public Button sendBtn;

    void OnClickSend(string sendLine)
    {
        Console.Send(sendLine);
        sendInput.text = "";
    }

    void OnChooseCategory(int index)
    {
        _categotyIndex = index;
        RefreshLog();
    }

    void RefreshCategory()
    {
        _categorysNames = Console.GetNamesCategory();
        categoryDrop.ClearOptions();
        categoryDrop.AddOptions(_categorysNames);
    }

    void RefreshLog()
    {
        if (_categotyIndex < _categorysNames.Count)
            logText.text = Console.GetCategoryLogString(_categorysNames[_categotyIndex]);
        else
            logText.text = "";
        TextGenerator textGen = new TextGenerator();
        TextGenerationSettings generationSettings = logText.GetGenerationSettings(logText.rectTransform.rect.size);
        float height = logText.preferredHeight;// textGen.GetPreferredHeight(logText.text, generationSettings);
        Vector2 size = rectContent.sizeDelta;
        size.y = height + 300;
        rectContent.sizeDelta = size;
    }

	// Use this for initialization
	void Start () {
        RefreshCategory();
        RefreshLog();
        categoryDrop.onValueChanged.AddListener((value) => OnChooseCategory(value));
        sendBtn.onClick.AddListener(() => OnClickSend(sendInput.text));
    }

    private float _timer = 0;
	// Update is called once per frame
	void Update () {
        _timer += Time.deltaTime;
        if(_timer > 0.8888888f)
        {
            RefreshCategory();
            RefreshLog();
            _timer = 0;
        }
    }
}
