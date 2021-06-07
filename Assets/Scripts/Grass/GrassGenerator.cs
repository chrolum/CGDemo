using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Saltsuica
{    
    public class GrassGenerator : MonoBehaviour
    {
        public GameObject grassPre;
        public Material grassMaterial;

        List<GameObject> grassMat;

        public int width;
        public int length;

        public float grassSize = 1;
        public float grassHeight = 1;

        List<MeshFilter> meshFilters = new List<MeshFilter>();
        CombineInstance[] combines;

        private void Start() {
            grassMat = new List<GameObject>();
            GenerateGrass();
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
                    grassMat.Add(go);
                }
            }

            combines = new CombineInstance[meshFilters.Count];
            for (int i = 0; i < combines.Length; i++)
            {
                combines[i].mesh = meshFilters[i].sharedMesh;
                combines[i].transform = meshFilters[i].transform.localToWorldMatrix;
                meshFilters[i].transform.parent.gameObject.SetActive(false);
                
            }
            transform.gameObject.AddComponent<MeshFilter>();
            transform.GetComponent<MeshFilter>().mesh = new Mesh();
            transform.GetComponent<MeshFilter>().mesh.CombineMeshes(combines);
            var meshRender = transform.gameObject.AddComponent<MeshRenderer>();
            meshRender.material = grassMaterial;
            transform.gameObject.SetActive(true);
        }
    }
}
