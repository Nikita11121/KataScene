using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace AlchemistRuntimeTool
{
    public class StatisticPanel : MonoBehaviour
    {

        public RectTransform itemsRect;

        private RectTransform[] _items;
        private int[] _values = new int[] { 0, 0, 0, 0, 0, 0, 0 };

        public void AddValue(int index)
        {
            _values[index]++;
            Refresh();
        }

        public void Refresh()
        {
            float sum = 0;
            for (int i = 0; i < _values.Length; i++)
                sum += _values[i];
            if (sum > 0)
            {
                float left = 0;
                for (int i = 0; i < _values.Length; i++)
                {
                    float koef = _values[i] / sum;
                    Vector2 size = _items[i].sizeDelta;
                    size.x = itemsRect.rect.width * koef;
                    _items[i].sizeDelta = size;
                    Vector2 pos = _items[i].anchoredPosition;
                    pos.x = itemsRect.rect.width * left;
                    _items[i].anchoredPosition = pos;
                    left += koef;
                    Text text = _items[i].Find("Text").GetComponent<Text>();
                    text.enabled = koef > 0.15f;
                    text.text = i * 10 + "-" + (int)(koef * 100) + "%";
                }
            }
        }

        public void SetValues(float[] values)
        {
            float sum = 0;
            for (int i = 0; i < values.Length; i++)
                sum += values[i];
        }

        // Use this for initialization
        void Start()
        {
            int n = itemsRect.childCount;
            _items = new RectTransform[n];
            for (int i = 0; i < n; i++)
                _items[i] = itemsRect.GetChild(i).GetComponent<RectTransform>();
        }

        // Update is called once per frame
        void Update()
        {

        }
    }
}
