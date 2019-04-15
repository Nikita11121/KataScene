using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.UI;

namespace AlchemistRuntimeTool
{
    public class RuntimeLogic : MonoBehaviour
    {
        public enum Status { DEBUG, RELEASE }
        public static Status status = Status.DEBUG;

        public RectTransform topRect;
        public Text fpsText;
        public Text fpsMinText;
        public Text fpsMidText;
        public Text fpsMaxText;
        public Text ramText;
        [Range(0, 0.99f)]
        public float fpsMidKoef = 0.9f;
        public Dropdown qualityDrop;
        public Text currPath;
        public Dropdown choosenDrop;
        public Toggle visibleObjTog;

        public Button consoleBtn;
        public RectTransform consoleRect;
        public Button valuesBtn;
        public RectTransform valuesRect;
        public StatisticPanel statisticPanel;

        private bool _isVisible = true;
        private float _currFps = 10;
        private float _minFps = -1;
        private double _midFps = -1;
        private float _maxFps = -1;
        private long _framesCount = 0;
        private Transform currTransform = null;
        private List<Transform> _tempTrans = new List<Transform>();
        private long[] numsFps = new long[7];

        private void UpdateTopVisible(float delta)
        {
            Vector2 pos = _isVisible ? Vector2.zero : new Vector2(0, topRect.sizeDelta.y);
            topRect.anchoredPosition = Vector2.Lerp(topRect.anchoredPosition, pos, delta);
        }

        private void OnChangeQuality(int value)
        {
            QualitySettings.SetQualityLevel(value);
        }

        private void OnChangeTransform(int value)
        {
            if (value <= 0)
                return;
            if (value == 1 && currTransform != null)
            {
                currTransform = currTransform.parent;

            }
            else if (currTransform == null)
            {
                currTransform = _tempTrans[value - 1];
            }
            else
            {
                currTransform = currTransform.GetChild(value - 2);
            }
            RefreshObjectsPanel();
        }

        private void VisibleObjTog(bool value)
        {
            if (currTransform != null)
            {
                currTransform.gameObject.SetActive(value);
            }
        }

        private void UpdateFps()
        {
            if (Time.timeSinceLevelLoad > 1)
            {
                float currFps = 1f / Time.deltaTime;
                if (_minFps < 0 || currFps < _minFps)
                    _minFps = currFps;
                _framesCount++;
                if (_midFps < 0)
                    _midFps = currFps;
                else
                    _midFps = _midFps * (_framesCount - 1) / _framesCount + currFps / _framesCount;
                if (_maxFps < 0 || currFps > _maxFps)
                    _maxFps = currFps;
                _currFps = _currFps * fpsMidKoef + (1 - fpsMidKoef) * currFps;
                fpsText.text = "FPS: " + Mathf.RoundToInt(_currFps);
                fpsMinText.text = "" + Mathf.RoundToInt(_minFps);
                fpsMidText.text = "" + Mathf.RoundToInt((float)_midFps);
                fpsMaxText.text = "" + Mathf.RoundToInt(_maxFps);
                statisticPanel.AddValue(Mathf.Min(6, (int)(currFps / 10)));
            }
        }

        private void RefreshObjectsPanel()
        {
            choosenDrop.ClearOptions();
            List<Dropdown.OptionData> transOption = new List<Dropdown.OptionData>();
            visibleObjTog.gameObject.SetActive(currTransform != null);
            if (currTransform == null)
            {
                currPath.text = "../";
                _tempTrans.Clear();
                GameObject[] allObjects = UnityEngine.Object.FindObjectsOfType<GameObject>();
                transOption.Add(new Dropdown.OptionData(""));
                for (int i = 0; i < allObjects.Length; i++)
                {
                    if (allObjects[i].transform.parent == null)
                    {
                        transOption.Add(new Dropdown.OptionData(allObjects[i].name));
                        _tempTrans.Add(allObjects[i].transform);
                    }
                }
            }
            else
            {
                visibleObjTog.isOn = currTransform.gameObject.active;
                currPath.text = "";
                Transform trans = currTransform;
                while (trans != null)
                {
                    currPath.text = "/" + trans.gameObject.name + currPath.text;
                    trans = trans.parent;
                }
                currPath.text = ".." + currPath.text;
                transOption.Add(new Dropdown.OptionData(""));
                transOption.Add(new Dropdown.OptionData(".."));
                for (int i = 0; i < currTransform.childCount; i++)
                {
                    transOption.Add(new Dropdown.OptionData(currTransform.GetChild(i).gameObject.name));
                }

            }
            choosenDrop.AddOptions(transOption);
            choosenDrop.value = 0;
        }

        // Use this for initialization
        void Start()
        {
            if (status == Status.RELEASE)
                Destroy(gameObject);
            _isVisible = false;
            qualityDrop.ClearOptions();
            List<Dropdown.OptionData> qualOption = new List<Dropdown.OptionData>();
            var levels = Enum.GetValues(typeof(QualityLevel));
            foreach (QualityLevel level in levels)
            {
                qualOption.Add(new Dropdown.OptionData(level.ToString()));
            }
            qualityDrop.AddOptions(qualOption);
            qualityDrop.onValueChanged.AddListener((value) => OnChangeQuality(value));
            qualityDrop.value = QualitySettings.GetQualityLevel();
            choosenDrop.onValueChanged.AddListener((value) => OnChangeTransform(value));
            visibleObjTog.onValueChanged.AddListener((value) => VisibleObjTog(value));
            UpdateTopVisible(1);
            RefreshObjectsPanel();
            consoleBtn.onClick.AddListener(() => consoleRect.gameObject.SetActive(!consoleRect.gameObject.active));
            consoleRect.gameObject.SetActive(false);
            valuesBtn.onClick.AddListener(() => valuesRect.gameObject.SetActive(!valuesRect.gameObject.active));
            valuesRect.gameObject.SetActive(false);
        }

        private int _lastNumTouch = 0;
        private float timer = 0;
        // Update is called once per frame
        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Tab) || _lastNumTouch >= 3)//(Input.touchCount == 3 && _lastNumTouch < 3))
                _isVisible = !_isVisible;
            UpdateTopVisible(Time.deltaTime * 4);
            UpdateFps();
            float ram = Profiler.GetTotalAllocatedMemoryLong() / 1024f / 1024f;
            if (ram < 1024)
                ramText.text = "RAM: " + Mathf.RoundToInt(ram) + "Мб";
            else
                ramText.text = "RAM: " + Mathf.Round(ram / 10.24f) / 100 + "Гб";
            _lastNumTouch = Input.touchCount;
            if (!_isVisible)
            {
                consoleRect.gameObject.SetActive(false);
                valuesRect.gameObject.SetActive(false);
            }
            timer += Time.deltaTime;
            if (timer > 3.11111111f)
            {
                RefreshObjectsPanel();
                timer = 0;
            }
        }
    }
}
