using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AlchemistLab
{
    public class SinMove : MonoBehaviour
    {
        [SerializeField] private float aplitude = 1f;

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            Vector3 pos = transform.position;
            pos.x = aplitude * Mathf.Sin(Time.time * 2);
            transform.position = pos;
        }
    }
}
