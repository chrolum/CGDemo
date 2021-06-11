using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Saltsuica
{    
    public class GrassGenerator : MonoBehaviour
    {
        public GameObject grassPre;
        public Material grassMaterial;

        List<GameObject> grassObj;

        public int width;
        public int length;

        public float grassSize = 1;
        public float grassHeight = 1;

        // wind area
        public float windAngle = 45f;
        public float windStrength = 1f;

        Vector2 windDir = new Vector2(0, 0);

        List<MeshFilter> meshFilters = new List<MeshFilter>();
        CombineInstance[] combines;

        private void Start() {
            grassObj = new List<GameObject>();
            GenerateGrass();
        }

        private void Update() {
            Shader.SetGlobalFloat ("_WindDirectionX", windDir.x);
            Shader.SetGlobalFloat ("_WindDirectionZ", windDir.y);
            Shader.SetGlobalFloat ("_WindStrength", windStrength);

            float shakeBending = Mathf.Lerp(0.5f, 2f, windStrength);
            Shader.SetGlobalFloat("_ShakeBending", shakeBending);
        }

        void GenerateGrass()
        {
            for (float x = 0; x < width; x += grassSize)
            {
                for (float z = 0; z < length; z += grassSize)
                {
                    float dx = Random.Range(0, grassSize);
                    float dz = Random.Range(0, grassSize);
                    Vector3 offset = new Vector3(x+dx, 0, z+dz);
                    //TODO: 用高斯分布
                    var h = Random.Range(0.3f, grassHeight);
                    var go = Instantiate(grassPre);
                    meshFilters.Add(go.GetComponentInChildren<MeshFilter>());
                    var scale = go.transform.localScale;
                    scale.y = h;
                    var angle = Random.Range(0, 90);
                    go.transform.rotation = go.transform.rotation * Quaternion.AngleAxis(angle, Vector3.up);
                    go.transform.localScale = scale;
                    go.transform.position = transform.position + offset;
                    grassObj.Add(go);
                }
            }

            combines = new CombineInstance[meshFilters.Count];
            for (int i = 0; i < combines.Length; i++)
            {
                combines[i].mesh = meshFilters[i].sharedMesh;
                combines[i].transform = meshFilters[i].transform.localToWorldMatrix;
                meshFilters[i].transform.parent.gameObject.SetActive(false);
                // Destroy()
                
            }
            transform.gameObject.AddComponent<MeshFilter>();
            transform.GetComponent<MeshFilter>().mesh = new Mesh();
            transform.GetComponent<MeshFilter>().mesh.CombineMeshes(combines);
            var meshRender = transform.gameObject.AddComponent<MeshRenderer>();
            meshRender.material = grassMaterial;
            transform.gameObject.SetActive(true);
        }

        private Vector2 GetWindDirByDeg(float angle)
        {
            float rad = angle * Mathf.Deg2Rad;
            var dir = new Vector2(Mathf.Cos(rad), Mathf.Sin(rad));
            return dir.normalized;
        }
    }


}
